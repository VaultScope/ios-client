import Foundation

public enum APIError: LocalizedError, Sendable {
    case badURL
    case unauthorized(String)
    case forbidden(String)
    case mfaRequired(String)
    case rateLimited(retryAfterSeconds: Int?)
    case offline
    case sslError(String)
    case serverError(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid API server URL configuration."
        case .unauthorized(let msg):
            return msg.isEmpty ? "Invalid credentials. Please verify your email and password." : msg
        case .forbidden(let msg):
            return msg.isEmpty ? "Access denied. Insufficient account permissions." : msg
        case .mfaRequired(let msg):
            return msg.isEmpty ? "Two-factor authentication code required." : msg
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter, seconds > 0 {
                return "Too many requests. Rate limit active, please wait \(seconds) seconds."
            }
            return "Too many requests. Please wait a moment before trying again."
        case .offline:
            return "No internet connection detected. Please verify your Wi-Fi or cellular connection."
        case .sslError(let detail):
            return "Secure transport failure: \(detail)"
        case .serverError(let code, let message):
            if code == 502 || code == 503 || code == 504 {
                return "VaultScope infrastructure gateway temporarily unavailable (\(code)). Retry in a moment."
            }
            return message
        case .decodingError(let detail):
            return "Response format mismatch: \(detail)"
        case .networkError(let detail):
            return "Network connection issue: \(detail)"
        case .unknown(let detail):
            return detail
        }
    }

    public var isMfaRequired: Bool {
        if case .mfaRequired = self { return true }
        return false
    }

    public var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }
}
