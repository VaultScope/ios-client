import Foundation

public struct LoginResponse: Decodable, Sendable {
    public let token: String
    public let username: String?
    public let name: String?
    public let emailVerified: Bool?

    enum CodingKeys: String, CodingKey {
        case token, username, name
        case emailVerified = "email_verified"
    }
}

public struct RegisterResponse: Decodable, Sendable {
    public let ok: Bool?
    public let message: String?
    public let token: String?
}

public actor AuthRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func login(email: String, password: String, totpCode: String? = nil) async throws -> (String, Customer) {
        let endpoint = Endpoint.login(email: email, password: password, totpCode: totpCode)
        let resp: LoginResponse = try await client.request(endpoint)
        await client.setToken(resp.token)

        // Attempt fetching full profile from /api/storefront/profile
        if let profile: Customer = try? await client.request(Endpoint.profile) {
            return (resp.token, profile)
        }

        let displayName = resp.name ?? resp.username ?? email
        let fallback = Customer(name: displayName, email: email, emailVerified: resp.emailVerified ?? false)
        return (resp.token, fallback)
    }

    public func register(
        username: String,
        name: String,
        email: String,
        password: String,
        company: String? = nil,
        address: String = "VaultScope Cloud",
        postalCode: String? = nil,
        city: String = "Berlin",
        country: String = "Germany",
        phone: String? = nil,
        vatId: String? = nil
    ) async throws -> (String?, Customer?, String) {
        let endpoint = Endpoint.register(
            username: username,
            name: name,
            email: email,
            password: password,
            company: company,
            address: address,
            postalCode: postalCode,
            city: city,
            country: country,
            phone: phone,
            vatId: vatId
        )
        let resp: RegisterResponse = try await client.request(endpoint)
        let msg = resp.message ?? "Account created successfully. Please verify your email."

        if let token = resp.token {
            await client.setToken(token)
            let cust = Customer(name: name, email: email, company: company ?? "", city: city, country: country)
            return (token, cust, msg)
        }

        return (nil, nil, msg)
    }

    public func verifyEmail(token: String) async throws -> String {
        let endpoint = Endpoint.verifyEmail(token: token)
        let resp: APIActionResponse = try await client.request(endpoint)
        return resp.message ?? "Email verified successfully."
    }

    public func resendVerification(email: String) async throws -> String {
        let endpoint = Endpoint.resendVerification(email: email)
        let resp: APIActionResponse = try await client.request(endpoint)
        return resp.message ?? "Verification link sent to your inbox."
    }

    public func logout() async {
        await client.setToken(nil)
    }
}
