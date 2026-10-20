import Foundation

public struct Customer: Identifiable, Codable, Sendable {
    public let id: UUID
    public var username: String
    public var name: String
    public var email: String
    public var phone: String
    public var company: String
    public var address: String
    public var postalCode: String
    public var city: String
    public var country: String
    public var vatId: String
    public var vatVerified: Bool
    public var status: String
    public var twoFactorEnabled: Bool
    public var emailVerified: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var lastLogin: Date?

    enum CodingKeys: String, CodingKey {
        case id, username, name, email, phone, company, address, city, country, status
        case postalCode = "postal_code"
        case vatId = "vat_id"
        case vatVerified = "vat_verified"
        case twoFactorEnabled = "two_factor_enabled"
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastLogin = "last_login"
    }

    public init(
        id: UUID = UUID(),
        username: String = "",
        name: String = "",
        email: String = "",
        phone: String = "",
        company: String = "",
        address: String = "",
        postalCode: String = "",
        city: String = "",
        country: String = "Germany",
        vatId: String = "",
        vatVerified: Bool = false,
        status: String = "active",
        twoFactorEnabled: Bool = false,
        emailVerified: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastLogin: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.name = name
        self.email = email
        self.phone = phone
        self.company = company
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.country = country
        self.vatId = vatId
        self.vatVerified = vatVerified
        self.status = status
        self.twoFactorEnabled = twoFactorEnabled
        self.emailVerified = emailVerified
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastLogin = lastLogin
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let str = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: str) {
            self.id = uuid
        } else {
            self.id = UUID()
        }

        self.username = (try? container.decode(String.self, forKey: .username)) ?? ""
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Client User"
        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.phone = (try? container.decode(String.self, forKey: .phone)) ?? ""
        self.company = (try? container.decode(String.self, forKey: .company)) ?? ""
        self.address = (try? container.decode(String.self, forKey: .address)) ?? ""
        self.postalCode = (try? container.decode(String.self, forKey: .postalCode)) ?? ""
        self.city = (try? container.decode(String.self, forKey: .city)) ?? ""
        self.country = (try? container.decode(String.self, forKey: .country)) ?? "Germany"
        self.vatId = (try? container.decode(String.self, forKey: .vatId)) ?? ""
        self.vatVerified = (try? container.decode(Bool.self, forKey: .vatVerified)) ?? false
        self.status = (try? container.decode(String.self, forKey: .status)) ?? "active"
        self.twoFactorEnabled = (try? container.decode(Bool.self, forKey: .twoFactorEnabled)) ?? false
        self.emailVerified = (try? container.decode(Bool.self, forKey: .emailVerified)) ?? true

        func parseDate(_ s: String) -> Date? {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: s) { return d }
            let isoStandard = ISO8601DateFormatter()
            if let d = isoStandard.date(from: s) { return d }
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            if let d = df.date(from: s) { return d }
            df.dateFormat = "yyyy-MM-dd"
            return df.date(from: s)
        }

        if let d = try? container.decode(Date.self, forKey: .createdAt) {
            self.createdAt = d
        } else if let s = try? container.decode(String.self, forKey: .createdAt), let d = parseDate(s) {
            self.createdAt = d
        } else {
            self.createdAt = Date()
        }

        if let d = try? container.decode(Date.self, forKey: .updatedAt) {
            self.updatedAt = d
        } else if let s = try? container.decode(String.self, forKey: .updatedAt), let d = parseDate(s) {
            self.updatedAt = d
        } else {
            self.updatedAt = self.createdAt
        }

        if let d = try? container.decode(Date.self, forKey: .lastLogin) {
            self.lastLogin = d
        } else if let s = try? container.decode(String.self, forKey: .lastLogin), let d = parseDate(s) {
            self.lastLogin = d
        } else {
            self.lastLogin = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(company, forKey: .company)
        try container.encode(address, forKey: .address)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(city, forKey: .city)
        try container.encode(country, forKey: .country)
        try container.encode(vatId, forKey: .vatId)
        try container.encode(vatVerified, forKey: .vatVerified)
        try container.encode(status, forKey: .status)
        try container.encode(twoFactorEnabled, forKey: .twoFactorEnabled)
        try container.encode(emailVerified, forKey: .emailVerified)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(lastLogin, forKey: .lastLogin)
    }
}
