import Foundation

extension Notification.Name {
    public static let vaultScopeUnauthorizedSession = Notification.Name("vaultScopeUnauthorizedSession")
}

public actor NetworkClient {
    public static let shared = NetworkClient()

    private var baseURL: URL
    private var token: String?
    private let session: URLSession

    // CSRF Cache
    private var cachedCsrfToken: String?
    private var csrfTimestamp: Date?

    public init(baseURL: URL = URL(string: "https://api.vaultscope.de")!) {
        self.baseURL = baseURL

        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    public func setBaseURL(_ url: URL) {
        self.baseURL = url
        self.cachedCsrfToken = nil
        self.csrfTimestamp = nil
    }

    public func getBaseURL() -> URL {
        return self.baseURL
    }

    public func setToken(_ token: String?) {
        self.token = token
    }

    public func getToken() -> String? {
        return self.token
    }

    // MARK: - CSRF Fetcher
    public func fetchCsrfToken() async -> String? {
        if let token = cachedCsrfToken, let ts = csrfTimestamp, Date().timeIntervalSince(ts) < 180 {
            return token
        }

        guard let url = buildURL(path: "/api/csrf") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 6.0
        applyStandardHeaders(to: &request)

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokenStr = json["token"] as? String else {
            return nil
        }

        self.cachedCsrfToken = tokenStr
        self.csrfTimestamp = Date()
        return tokenStr
    }

    // MARK: - Health Check
    public func checkHealth() async -> Bool {
        guard let url = buildURL(path: "/api/health") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 4.0
        applyStandardHeaders(to: &request)

        guard let (_, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return false
        }
        return true
    }

    // MARK: - Request Execution with Automatic Retry
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, _) = try await performRequestWithRetry(endpoint)
        do {
            return try JSONDecoder.vaultScope.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        _ = try await performRequestWithRetry(endpoint)
    }

    public func requestData(_ endpoint: Endpoint) async throws -> Data {
        let (data, _) = try await performRequestWithRetry(endpoint)
        return data
    }

    // MARK: - Retry Strategy for Idempotent Reads
    private func performRequestWithRetry(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        // Fast offline check
        if !NetworkMonitor.shared.isConnected {
            throw APIError.offline
        }

        let isIdempotent = (endpoint.method == .get)
        let maxAttempts = isIdempotent ? 3 : 1
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await performRequest(endpoint)
            } catch let err as APIError {
                // Do not retry authorization, client validation, or rate limit errors
                if case .unauthorized = err { throw err }
                if case .mfaRequired = err { throw err }
                if case .forbidden = err { throw err }
                if case .rateLimited = err { throw err }

                lastError = err
                if attempt < maxAttempts {
                    let delay = Double(attempt) * 0.4
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    let delay = Double(attempt) * 0.4
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        if let apiErr = lastError as? APIError {
            throw apiErr
        }
        throw APIError.networkError(lastError?.localizedDescription ?? "Request failed after multiple attempts.")
    }

    private func performRequest(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        guard let url = buildURL(path: endpoint.path) else {
            throw APIError.badURL
        }

        // Enforce HTTPS security on public endpoints
        if let host = url.host?.lowercased(),
           url.scheme == "http",
           !isLocalOrPrivateHost(host) {
            throw APIError.sslError("Insecure HTTP connections are prohibited on public infrastructure endpoints. HTTPS is strictly enforced.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        applyStandardHeaders(to: &request)

        if let body = endpoint.bodyData {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Auto-seed from persistent session storage if memory token was not yet set
        var activeToken = token
        if activeToken == nil || activeToken?.isEmpty == true {
            activeToken = SessionStorage.shared.loadToken()
            self.token = activeToken
        }

        if let bearer = activeToken, !bearer.isEmpty {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }

        if endpoint.isMutating {
            if let csrf = await fetchCsrfToken() {
                request.setValue(csrf, forHTTPHeaderField: "x-csrf-token")
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid server response format.")
        }

        // Check for MFA challenge
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let mfaRequired = json["mfa_required"] as? Bool, mfaRequired {
            let msg = json["message"] as? String ?? "Two-factor authentication code required."
            throw APIError.mfaRequired(msg)
        }

        // Handle 401 Unauthorized
        if httpResponse.statusCode == 401 {
            let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Unauthorized session."
            // Only trigger session expiration if an authenticated token was actually sent with this request
            let tokenWasTransmitted = request.value(forHTTPHeaderField: "Authorization") != nil
            if tokenWasTransmitted {
                Task { @MainActor in
                    NotificationCenter.default.post(name: .vaultScopeUnauthorizedSession, object: nil)
                }
            }
            throw APIError.unauthorized(errorMsg)
        }

        // Handle 403 Forbidden
        if httpResponse.statusCode == 403 {
            let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Access forbidden."
            throw APIError.forbidden(errorMsg)
        }

        // Handle 429 Too Many Requests
        if httpResponse.statusCode == 429 {
            var retrySeconds: Int? = nil
            if let retryHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
               let seconds = Int(retryHeader) {
                retrySeconds = seconds
            }
            throw APIError.rateLimited(retryAfterSeconds: retrySeconds)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMsg = json?["error"] as? String ?? (json?["message"] as? String ?? "Request failed with HTTP \(httpResponse.statusCode)")
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMsg)
        }

        return (data, httpResponse)
    }

    private func applyStandardHeaders(to request: inout URLRequest) {
        request.setValue("VaultScope-iOS/1.1 (Apple; iOS; EnterpriseClient)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    }

    private func isLocalOrPrivateHost(_ host: String) -> Bool {
        if host == "localhost" || host == "127.0.0.1" { return true }
        if host.starts(with: "10.") || host.starts(with: "192.168.") { return true }
        if host.starts(with: "172.") { return true }
        return false
    }

    private func buildURL(path: String) -> URL? {
        let baseStr = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(baseStr)/\(cleanPath)")
    }
}
