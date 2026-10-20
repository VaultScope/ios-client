import Foundation

public struct APIActionResponse: Decodable, Sendable {
    public let message: String?
    public let error: String?
    public let success: Bool?

    public init(message: String? = nil, error: String? = nil, success: Bool? = nil) {
        self.message = message
        self.error = error
        self.success = success
    }
}

public struct VatVerificationResponse: Decodable, Sendable {
    public let valid: Bool?
    public let message: String?
    public let company_name: String?

    public init(valid: Bool? = nil, message: String? = nil, company_name: String? = nil) {
        self.valid = valid
        self.message = message
        self.company_name = company_name
    }
}

public struct ConsoleResponse: Decodable, Sendable {
    public let url: String?
    public let wss_url: String?

    public init(url: String? = nil, wss_url: String? = nil) {
        self.url = url
        self.wss_url = wss_url
    }
}

public struct PaymentIntentResponse: Decodable, Sendable {
    public let client_secret: String?
    public let clientSecret: String?

    public init(client_secret: String? = nil, clientSecret: String? = nil) {
        self.client_secret = client_secret
        self.clientSecret = clientSecret
    }
}
