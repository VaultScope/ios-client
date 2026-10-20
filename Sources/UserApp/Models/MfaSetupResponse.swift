import Foundation

public struct MfaSetupResponse: Codable, Sendable {
    public var secret: String
    public var qrBase64: String
    public var url: String

    enum CodingKeys: String, CodingKey {
        case secret, url
        case qrBase64 = "qr_base64"
    }

    public init(secret: String = "", qrBase64: String = "", url: String = "") {
        self.secret = secret
        self.qrBase64 = qrBase64
        self.url = url
    }
}
