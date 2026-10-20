import Foundation
import SwiftUI

public enum ActivityType: String, Codable, Sendable {
    case serverReboot = "server_reboot"
    case serverStarted = "server_started"
    case serverStopped = "server_stopped"
    case orderProvisioned = "order_provisioned"
    case invoicePaid = "invoice_paid"
    case ticketReply = "ticket_reply"
    case securityAlert = "security_alert"
    case general = "general"

    public var icon: String {
        switch self {
        case .serverReboot: return "arrow.clockwise"
        case .serverStarted: return "play.fill"
        case .serverStopped: return "stop.fill"
        case .orderProvisioned: return "server.rack"
        case .invoicePaid: return "checkmark.seal.fill"
        case .ticketReply: return "bubble.left.and.bubble.right.fill"
        case .securityAlert: return "shield.checkered"
        case .general: return "clock.arrow.circlepath"
        }
    }

    public var color: Color {
        switch self {
        case .serverReboot: return VaultTheme.cyan
        case .serverStarted: return VaultTheme.emerald
        case .serverStopped: return VaultTheme.textMuted
        case .orderProvisioned: return VaultTheme.purple
        case .invoicePaid: return VaultTheme.emerald
        case .ticketReply: return VaultTheme.amber
        case .securityAlert: return VaultTheme.rose
        case .general: return VaultTheme.cyan
        }
    }
}

public struct ActivityItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var detail: String
    public var type: ActivityType
    public var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, title, detail, type, timestamp
        case action, target
        case createdAt = "created_at"
    }

    public init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        type: ActivityType = .general,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.type = type
        self.timestamp = timestamp
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

        self.detail = (try? container.decode(String.self, forKey: .detail)) ?? ""

        // Title: try direct title, else action or target
        if let t = try? container.decode(String.self, forKey: .title), !t.isEmpty {
            self.title = t
        } else if let act = try? container.decode(String.self, forKey: .action), !act.isEmpty {
            self.title = act.capitalized
        } else if let tgt = try? container.decode(String.self, forKey: .target), !tgt.isEmpty {
            self.title = tgt
        } else {
            self.title = "Activity Event"
        }

        // Type mapping
        if let explicitType = try? container.decode(ActivityType.self, forKey: .type) {
            self.type = explicitType
        } else if let rawAction = (try? container.decode(String.self, forKey: .action)) ?? (try? container.decode(String.self, forKey: .type)) {
            let lower = rawAction.lowercased()
            if lower.contains("reboot") || lower.contains("restart") {
                self.type = .serverReboot
            } else if lower.contains("start") {
                self.type = .serverStarted
            } else if lower.contains("stop") {
                self.type = .serverStopped
            } else if lower.contains("order") || lower.contains("provision") {
                self.type = .orderProvisioned
            } else if lower.contains("invoice") || lower.contains("paid") {
                self.type = .invoicePaid
            } else if lower.contains("ticket") {
                self.type = .ticketReply
            } else if lower.contains("auth") || lower.contains("login") || lower.contains("register") || lower.contains("security") {
                self.type = .securityAlert
            } else {
                self.type = .general
            }
        } else {
            self.type = .general
        }

        func parseDate(_ s: String) -> Date? {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: s) { return d }
            let isoStandard = ISO8601DateFormatter()
            return isoStandard.date(from: s)
        }

        if let d = try? container.decode(Date.self, forKey: .timestamp) {
            self.timestamp = d
        } else if let s = try? container.decode(String.self, forKey: .timestamp), let d = parseDate(s) {
            self.timestamp = d
        } else if let d = try? container.decode(Date.self, forKey: .createdAt) {
            self.timestamp = d
        } else if let s = try? container.decode(String.self, forKey: .createdAt), let d = parseDate(s) {
            self.timestamp = d
        } else {
            self.timestamp = Date()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(detail, forKey: .detail)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
    }

    public var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
