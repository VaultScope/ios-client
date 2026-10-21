import Foundation
import SwiftUI
import UserNotifications
import Combine

@MainActor
public final class TicketNotificationEngine: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = TicketNotificationEngine()

    // MARK: - Published State
    @Published public var activeToast: TicketToastItem? = nil
    @Published public var unreadCount: Int = 0
    @Published public var hasPermission: Bool = false
    @Published public var isPollingActive: Bool = false

    // MARK: - Navigation Callback
    public var onNavigateToTicket: ((UUID) -> Void)?

    // MARK: - Internal Storage
    private var ticketSnapshots: [UUID: TicketSnapshot] = [:]
    private var pollingTask: Task<Void, Never>?
    private var toastDismissTask: Task<Void, Never>?
    private let snapshotsKey = "vaultscope_ticket_snapshots_v1"
    private var isFirstSync: Bool = true

    override private init() {
        super.init()
        loadSnapshots()
    }

    // MARK: - Engine Lifecycle & Setup
    public func setup() {
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.hasPermission = granted
            }
        }
    }

    // MARK: - Polling Loop Control
    public func startPolling(ticketsRepo: TicketsRepository) {
        guard pollingTask == nil else { return }
        isPollingActive = true

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }

                await self.poll(ticketsRepo: ticketsRepo)

                // Poll every 6 seconds during active session
                try? await Task.sleep(nanoseconds: 6_000_000_000)
            }
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPollingActive = false
    }

    // MARK: - Core Polling & Delta Evaluation
    public func poll(ticketsRepo: TicketsRepository) async {
        do {
            let tickets = try await ticketsRepo.fetchTickets()
            await evaluateTicketDeltas(liveTickets: tickets, ticketsRepo: ticketsRepo)
        } catch {
            // Network hiccups are handled silently without disturbing user experience
        }
    }

    public func evaluateTicketDeltas(liveTickets: [Ticket], ticketsRepo: TicketsRepository) async {
        var newlyDetectedToasts: [TicketToastItem] = []

        for ticket in liveTickets {
            if let previous = ticketSnapshots[ticket.id] {
                // 1. Detect Ticket Status Transition
                if previous.status != ticket.status {
                    let statusTitle = ticket.status.title
                    let toast = TicketToastItem(
                        ticketId: ticket.id,
                        ticketNumber: ticket.ticketNumber,
                        title: "Ticket Status: \(statusTitle)",
                        message: "\"\(ticket.subject)\" is now marked as \(statusTitle).",
                        notificationType: .statusChanged,
                        status: ticket.status
                    )
                    newlyDetectedToasts.append(toast)

                    // Update snapshot with new status
                    var updated = previous
                    updated.status = ticket.status
                    updated.updatedAt = ticket.updatedAt
                    if ticket.status == .waitingCustomer {
                        updated.isRead = false
                    }
                    ticketSnapshots[ticket.id] = updated
                }

                // 2. Detect New Messages or Updated Content
                if ticket.updatedAt > previous.updatedAt {
                    if let detail = try? await ticketsRepo.fetchTicketDetail(id: ticket.id) {
                        let newMessages = detail.messages.filter { msg in
                            if let lastMsgId = previous.lastMessageId {
                                return msg.id != lastMsgId && msg.createdAt > previous.updatedAt
                            }
                            return msg.createdAt > previous.updatedAt
                        }

                        // Check for staff replies specifically
                        let staffReplies = newMessages.filter { $0.isStaff }
                        if let latestStaff = staffReplies.last {
                            let toast = TicketToastItem(
                                ticketId: ticket.id,
                                ticketNumber: ticket.ticketNumber,
                                title: "Support Reply: \(ticket.ticketNumber)",
                                message: "\(latestStaff.authorName): \"\(latestStaff.content.trimmingCharacters(in: .whitespacesAndNewlines))\"",
                                notificationType: .newStaffMessage,
                                status: ticket.status,
                                authorName: latestStaff.authorName
                            )
                            newlyDetectedToasts.append(toast)

                            var updated = ticketSnapshots[ticket.id] ?? previous
                            updated.isRead = false
                            updated.messageCount = detail.messages.count
                            updated.lastMessageId = detail.messages.last?.id
                            updated.updatedAt = ticket.updatedAt
                            ticketSnapshots[ticket.id] = updated
                        } else {
                            var updated = ticketSnapshots[ticket.id] ?? previous
                            updated.messageCount = detail.messages.count
                            updated.lastMessageId = detail.messages.last?.id
                            updated.updatedAt = ticket.updatedAt
                            ticketSnapshots[ticket.id] = updated
                        }
                    }
                }
            } else {
                // New ticket registered in system
                let isWaiting = ticket.status == .waitingCustomer
                let snap = TicketSnapshot(
                    id: ticket.id,
                    ticketNumber: ticket.ticketNumber,
                    status: ticket.status,
                    updatedAt: ticket.updatedAt,
                    messageCount: ticket.messages.count,
                    lastMessageId: ticket.messages.last?.id,
                    isRead: !isWaiting
                )
                ticketSnapshots[ticket.id] = snap

                // If not first cold launch sync, notify of newly discovered ticket
                if !isFirstSync {
                    let toast = TicketToastItem(
                        ticketId: ticket.id,
                        ticketNumber: ticket.ticketNumber,
                        title: "New Ticket Registered",
                        message: "\(ticket.ticketNumber) — \(ticket.subject)",
                        notificationType: .generalUpdate,
                        status: ticket.status
                    )
                    newlyDetectedToasts.append(toast)
                }
            }
        }

        isFirstSync = false
        saveSnapshots()
        recalculateUnreadCount()

        // Dispatch notifications for detected events
        for toast in newlyDetectedToasts {
            deliverNotification(toast)
        }
    }

    // MARK: - Notification Delivery (Dual-Layer: In-App Toast & System Push)
    public func deliverNotification(_ item: TicketToastItem) {
        // 1. In-App Liquid Glass Toast
        presentToast(item)

        // 2. Native System Local Notification (when backgrounded or banner alert)
        scheduleSystemNotification(for: item)

        // 3. Haptic Feedback
        triggerNotificationHaptic(for: item.notificationType)
    }

    public func presentToast(_ item: TicketToastItem) {
        toastDismissTask?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.activeToast = item
        }

        // Auto-dismiss after 6 seconds
        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard let self = self else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                if self.activeToast?.id == item.id {
                    self.activeToast = nil
                }
            }
        }
    }

    public func dismissActiveToast() {
        toastDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            self.activeToast = nil
        }
    }

    private func scheduleSystemNotification(for item: TicketToastItem) {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.subtitle = item.ticketNumber
        content.body = item.message
        content.sound = .default
        content.userInfo = ["ticketId": item.ticketId.uuidString]

        let count = max(self.unreadCount, 1)
        content.badge = NSNumber(value: count)

        let request = UNNotificationRequest(
            identifier: "ticket-\(item.ticketId.uuidString)-\(item.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    private func triggerNotificationHaptic(for type: TicketNotificationType) {
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .statusChanged:
            generator.notificationOccurred(.warning)
        case .newStaffMessage:
            generator.notificationOccurred(.success)
        case .generalUpdate:
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Read & Badge Management
    public func markTicketAsRead(ticketId: UUID) {
        if var snap = ticketSnapshots[ticketId] {
            snap.isRead = true
            ticketSnapshots[ticketId] = snap
            saveSnapshots()
            recalculateUnreadCount()
        }
    }

    public func recalculateUnreadCount() {
        let unread = ticketSnapshots.values.filter { !$0.isRead || $0.status == .waitingCustomer }.count
        self.unreadCount = unread

        // Update system application badge
        UNUserNotificationCenter.current().setBadgeCount(unread) { _ in }
    }

    // MARK: - Deep Linking
    public func handleDeepLink(ticketId: UUID) {
        dismissActiveToast()
        markTicketAsRead(ticketId: ticketId)
        onNavigateToTicket?(ticketId)
    }

    // MARK: - Snapshot Persistence
    private func saveSnapshots() {
        if let data = try? JSONEncoder().encode(ticketSnapshots) {
            UserDefaults.standard.set(data, forKey: snapshotsKey)
        }
    }

    private func loadSnapshots() {
        if let data = UserDefaults.standard.data(forKey: snapshotsKey),
           let decoded = try? JSONDecoder().decode([UUID: TicketSnapshot].self, from: data) {
            self.ticketSnapshots = decoded
            recalculateUnreadCount()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let idString = userInfo["ticketId"] as? String,
           let uuid = UUID(uuidString: idString) {
            Task { @MainActor in
                TicketNotificationEngine.shared.handleDeepLink(ticketId: uuid)
            }
        }
        completionHandler()
    }
}
