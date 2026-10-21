import Foundation
import SwiftUI

public enum TicketNotificationType: String, Codable, Sendable, Hashable {
    case statusChanged
    case newStaffMessage
    case generalUpdate
}

public struct TicketToastItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let ticketId: UUID
    public let ticketNumber: String
    public let title: String
    public let message: String
    public let notificationType: TicketNotificationType
    public let status: TicketStatus?
    public let authorName: String?
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        ticketId: UUID,
        ticketNumber: String,
        title: String,
        message: String,
        notificationType: TicketNotificationType,
        status: TicketStatus? = nil,
        authorName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.ticketId = ticketId
        self.ticketNumber = ticketNumber
        self.title = title
        self.message = message
        self.notificationType = notificationType
        self.status = status
        self.authorName = authorName
        self.timestamp = timestamp
    }

    public var iconName: String {
        switch notificationType {
        case .statusChanged:
            switch status {
            case .open: return "arrow.up.circle.fill"
            case .inProgress: return "gearshape.arrow.triangle.2.circlepath"
            case .waitingCustomer: return "exclamationmark.bubble.fill"
            case .closed: return "checkmark.seal.fill"
            case .none: return "bell.badge.fill"
            }
        case .newStaffMessage:
            return "shield.fill"
        case .generalUpdate:
            return "bell.fill"
        }
    }

    public var accentColor: Color {
        switch notificationType {
        case .statusChanged:
            return status?.color ?? VaultTheme.accentBright
        case .newStaffMessage:
            return VaultTheme.cyan
        case .generalUpdate:
            return VaultTheme.accentBright
        }
    }
}

public struct TicketSnapshot: Codable, Sendable, Hashable {
    public let id: UUID
    public let ticketNumber: String
    public var status: TicketStatus
    public var updatedAt: Date
    public var messageCount: Int
    public var lastMessageId: UUID?
    public var isRead: Bool

    public init(
        id: UUID,
        ticketNumber: String,
        status: TicketStatus,
        updatedAt: Date,
        messageCount: Int = 0,
        lastMessageId: UUID? = nil,
        isRead: Bool = true
    ) {
        self.id = id
        self.ticketNumber = ticketNumber
        self.status = status
        self.updatedAt = updatedAt
        self.messageCount = messageCount
        self.lastMessageId = lastMessageId
        self.isRead = isRead
    }
}
