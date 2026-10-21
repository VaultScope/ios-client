import SwiftUI

public struct TicketDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    public let ticketId: UUID
    @State private var replyText: String = ""
    @State private var isSending: Bool = false
    @State private var sseClient: TicketSSEClient? = nil
    @State private var isRealtimeActive: Bool = false

    private var ticket: Ticket? {
        appState.tickets.first(where: { $0.id == ticketId })
    }

    public init(ticketId: UUID) {
        self.ticketId = ticketId
    }

    public var body: some View {
        Group {
            if let tkt = ticket {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header Meta Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text(tkt.ticketNumber)
                                        .font(.caption.monospaced())
                                        .foregroundColor(VaultTheme.accentBright)

                                    // Realtime Live SSE Indicator
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(isRealtimeActive ? VaultTheme.emerald : VaultTheme.accentBright)
                                            .frame(width: 6, height: 6)
                                        Text(isRealtimeActive ? "LIVE SSE" : "SYNCED")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(isRealtimeActive ? VaultTheme.emerald : VaultTheme.accentBright)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(VaultTheme.subtle)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder((isRealtimeActive ? VaultTheme.emerald : VaultTheme.accentBright).opacity(0.3), lineWidth: 1)
                                    )

                                    Spacer()
                                    StatusPill(title: tkt.status.title, color: tkt.status.color)
                                }

                                Text(tkt.subject)
                                    .font(.headline)
                                    .foregroundColor(VaultTheme.textPrimary)

                                HStack {
                                    Label(tkt.category.capitalized, systemImage: "folder.fill")
                                        .font(.caption)
                                        .foregroundColor(VaultTheme.textMuted)

                                    Spacer()

                                    Label("Priority: \(tkt.priority.title)", systemImage: "flag.fill")
                                        .font(.caption)
                                        .foregroundColor(tkt.priority.color)
                                }

                                if let srv = tkt.relatedServiceName {
                                    HStack {
                                        Label("Service: \(srv)", systemImage: "server.rack")
                                            .font(.caption.monospaced())
                                            .foregroundColor(VaultTheme.textFaint)
                                    }
                                }
                            }
                            .obsidianCard(cornerRadius: 14, padding: 14)

                            // Message Thread
                            if tkt.messages.isEmpty {
                                Text("No messages recorded in this ticket thread yet.")
                                    .font(.subheadline)
                                    .foregroundColor(VaultTheme.textMuted)
                                    .padding(.vertical, 16)
                            } else {
                                ForEach(tkt.messages) { msg in
                                    VStack(alignment: msg.isStaff ? .leading : .trailing, spacing: 4) {
                                        HStack(spacing: 4) {
                                            if msg.isStaff {
                                                Image(systemName: "shield.fill")
                                                    .font(.caption2)
                                                    .foregroundColor(VaultTheme.accentBright)
                                            }

                                            Text(msg.authorName)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(msg.isStaff ? VaultTheme.accentBright : VaultTheme.textPrimary)

                                            Text("• \(msg.formattedDate)")
                                                .font(.caption2)
                                                .foregroundColor(VaultTheme.textFaint)
                                        }

                                        Text(msg.content)
                                            .font(.subheadline)
                                            .foregroundColor(VaultTheme.textPrimary)
                                            .padding(12)
                                            .background(msg.isStaff ? VaultTheme.card : VaultTheme.subtle)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(msg.isStaff ? VaultTheme.accentBright.opacity(0.3) : VaultTheme.line, lineWidth: 1)
                                            )
                                    }
                                    .frame(maxWidth: .infinity, alignment: msg.isStaff ? .leading : .trailing)
                                }
                            }
                        }
                        .padding(16)
                    }

                    // Native Reply Input Bar
                    if tkt.status != .closed {
                        VStack(spacing: 0) {
                            Divider().background(VaultTheme.line)
                            HStack(spacing: 10) {
                                TextField("Type a reply...", text: $replyText)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(VaultTheme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(VaultTheme.line, lineWidth: 1)
                                    )

                                Button {
                                    sendReply()
                                } label: {
                                    if isSending {
                                        ProgressView()
                                            .tint(VaultTheme.accentBright)
                                    } else {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(VaultTheme.accentBright)
                                    }
                                }
                                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(VaultTheme.obsidian)
                        }
                    }
                }
                .background(VaultTheme.obsidian.ignoresSafeArea())
                .navigationTitle(tkt.ticketNumber)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await appState.refreshTicketDetail(ticketId: ticketId)
                }
                .task {
                    appState.markTicketAsRead(ticketId: ticketId)
                    await appState.refreshTicketDetail(ticketId: ticketId)

                    // Connect Realtime SSE Stream for instant incoming replies
                    if let url = URL(string: appState.apiBaseURL) {
                        let client = TicketSSEClient(
                            ticketId: ticketId,
                            baseURL: url,
                            token: appState.savedApiToken.isEmpty ? nil : appState.savedApiToken,
                            onMessage: { msg in
                                Task { @MainActor in
                                    appState.appendRealtimeMessage(ticketId: ticketId, message: msg)
                                    appState.markTicketAsRead(ticketId: ticketId)
                                }
                            },
                            onConnectionChange: { active in
                                Task { @MainActor in
                                    self.isRealtimeActive = active
                                }
                            }
                        )
                        self.sseClient = client
                        client.connect()
                    }
                }
                .onDisappear {
                    sseClient?.disconnect()
                    sseClient = nil
                }
            } else {
                ContentUnavailableView("Ticket Not Found", systemImage: "bubble.left.and.bubble.right")
            }
        }
    }

    private func sendReply() {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        appState.replyToTicket(ticketId: ticketId, messageText: trimmed)
        replyText = ""
        isSending = false
    }
}
