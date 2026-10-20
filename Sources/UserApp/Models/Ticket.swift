import Foundation
import SwiftUI

public enum TicketStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case open = "open"
    case inProgress = "in_progress"
    case waitingCustomer = "waiting_customer"
    case closed = "closed"

    public var title: String {
        switch self {
        case .open: return "OPEN"
        case .inProgress: return "IN PROGRESS"
        case .waitingCustomer: return "WAITING ON YOU"
        case .closed: return "RESOLVED"
        }
    }

    public var color: Color {
        switch self {
        case .open: return VaultTheme.amber
        case .inProgress: return VaultTheme.cyan
        case .waitingCustomer: return VaultTheme.purple
        case .closed: return VaultTheme.emerald
        }
    }
}

public enum TicketPriority: String, Codable, CaseIterable, Sendable, Hashable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"

    public var title: String {
        rawValue.capitalized
    }

    public var color: Color {
        switch self {
        case .low: return VaultTheme.textMuted
        case .normal: return VaultTheme.textSecondary
        case .high: return VaultTheme.amber
        case .critical: return VaultTheme.rose
        }
    }
}

public struct TicketMessage: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var authorName: String
    public var isStaff: Bool
    public var content: String
    public var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, content
        case authorName = "author_name"
        case authorType = "author_type"
        case isStaff = "is_staff"
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        authorName: String = "Client",
        isStaff: Bool = false,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.authorName = authorName
        self.isStaff = isStaff
        self.content = content
        self.createdAt = createdAt
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

        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""

        var staffFlag = (try? container.decode(Bool.self, forKey: .isStaff)) ?? false
        if let authorType = try? container.decode(String.self, forKey: .authorType) {
            if authorType.lowercased() == "staff" || authorType.lowercased() == "admin" {
                staffFlag = true
            }
        }
        self.isStaff = staffFlag

        let defaultName = staffFlag ? "VaultScope Engineer" : "Client"
        self.authorName = (try? container.decode(String.self, forKey: .authorName)) ?? defaultName

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
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(authorName, forKey: .authorName)
        try container.encode(isStaff, forKey: .isStaff)
        try container.encode(createdAt, forKey: .createdAt)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

public struct TicketWithMessagesResponse: Codable {
    public let ticket: Ticket
    public let messages: [TicketMessage]
}

public struct Ticket: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var ticketNumber: String
    public var category: String
    public var subject: String
    public var status: TicketStatus
    public var priority: TicketPriority
    public var relatedServiceName: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var messages: [TicketMessage]

    enum CodingKeys: String, CodingKey {
        case id, category, subject, status, priority, messages
        case ticketNumber = "ticket_number"
        case relatedServiceName = "related_service_name"
        case relatedServiceId = "related_service_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        ticketNumber: String,
        category: String = "support",
        subject: String,
        status: TicketStatus = .open,
        priority: TicketPriority = .normal,
        relatedServiceName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [TicketMessage] = []
    ) {
        self.id = id
        self.ticketNumber = ticketNumber
        self.category = category
        self.subject = subject
        self.status = status
        self.priority = priority
        self.relatedServiceName = relatedServiceName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
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

        self.ticketNumber = (try? container.decode(String.self, forKey: .ticketNumber)) ?? "TKT-0000"

        let rawCat = (try? container.decode(String.self, forKey: .category)) ?? "support"
        switch rawCat.lowercased() {
        case "support": self.category = "Technical Support"
        case "abuse": self.category = "Abuse & Security"
        case "dmca": self.category = "DMCA & Legal"
        default: self.category = rawCat.capitalized
        }

        self.subject = (try? container.decode(String.self, forKey: .subject)) ?? "Support Ticket"
        self.status = (try? container.decode(TicketStatus.self, forKey: .status)) ?? .open
        self.priority = (try? container.decode(TicketPriority.self, forKey: .priority)) ?? .normal
        self.relatedServiceName = try? container.decode(String.self, forKey: .relatedServiceName)
        self.messages = (try? container.decode([TicketMessage].self, forKey: .messages)) ?? []

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

        if let d = try? container.decode(Date.self, forKey: .updatedAt) {
            self.updatedAt = d
        } else if let s = try? container.decode(String.self, forKey: .updatedAt), let d = parseDate(s) {
            self.updatedAt = d
        } else {
            self.updatedAt = self.createdAt
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ticketNumber, forKey: .ticketNumber)
        try container.encode(category, forKey: .category)
        try container.encode(subject, forKey: .subject)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        try container.encodeIfPresent(relatedServiceName, forKey: .relatedServiceName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(messages, forKey: .messages)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: updatedAt)
    }
}
