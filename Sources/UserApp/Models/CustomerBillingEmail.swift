import Foundation

public struct CustomerBillingEmail: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var customerId: UUID
    public var email: String
    public var verified: Bool
    public var createdAt: Date
    public var verifiedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, verified
        case customerId = "customer_id"
        case createdAt = "created_at"
        case verifiedAt = "verified_at"
    }

    public init(
        id: UUID = UUID(),
        customerId: UUID = UUID(),
        email: String,
        verified: Bool = false,
        createdAt: Date = Date(),
        verifiedAt: Date? = nil
    ) {
        self.id = id
        self.customerId = customerId
        self.email = email
        self.verified = verified
        self.createdAt = createdAt
        self.verifiedAt = verifiedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let u = try? container.decode(UUID.self, forKey: .id) {
            self.id = u
        } else if let s = try? container.decode(String.self, forKey: .id), let u = UUID(uuidString: s) {
            self.id = u
        } else {
            self.id = UUID()
        }

        if let u = try? container.decode(UUID.self, forKey: .customerId) {
            self.customerId = u
        } else if let s = try? container.decode(String.self, forKey: .customerId), let u = UUID(uuidString: s) {
            self.customerId = u
        } else {
            self.customerId = UUID()
        }

        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.verified = (try? container.decode(Bool.self, forKey: .verified)) ?? false

        func parseDate(_ s: String) -> Date? {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: s) { return d }
            let isoStandard = ISO8601DateFormatter()
            return isoStandard.date(from: s)
        }

        if let d = try? container.decode(Date.self, forKey: .createdAt) {
            self.createdAt = d
        } else if let s = try? container.decode(String.self, forKey: .createdAt), let d = parseDate(s) {
            self.createdAt = d
        } else {
            self.createdAt = Date()
        }

        if let d = try? container.decode(Date.self, forKey: .verifiedAt) {
            self.verifiedAt = d
        } else if let s = try? container.decode(String.self, forKey: .verifiedAt), let d = parseDate(s) {
            self.verifiedAt = d
        } else {
            self.verifiedAt = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(email, forKey: .email)
        try container.encode(verified, forKey: .verified)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(verifiedAt, forKey: .verifiedAt)
    }
}
