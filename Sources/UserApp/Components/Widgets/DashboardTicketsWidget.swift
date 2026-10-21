import SwiftUI

public struct DashboardTicketsWidget: View {
    @EnvironmentObject var appState: AppState
    public let onSelect: () -> Void

    public init(onSelect: @escaping () -> Void) {
        self.onSelect = onSelect
    }

    private var latestTicket: Ticket? {
        appState.tickets.first
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Header Row
                HStack {
                    ZStack {
                        Circle()
                            .fill(VaultTheme.accentSubtle)
                            .frame(width: 32, height: 32)
                        Image(systemName: "lifepreserver.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(VaultTheme.accentBright)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SUPPORT & SLA")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(VaultTheme.textFaint)
                        Text("24/7 Engineer Access")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(VaultTheme.textSecondary)
                    }

                    Spacer()

                    if appState.waitingCustomerTicketsCount > 0 {
                        Text("\(appState.waitingCustomerTicketsCount) WAITING ON YOU")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(VaultTheme.purple)
                            .clipShape(Capsule())
                    } else if appState.openTicketsCount > 0 {
                        StatusPill(title: "\(appState.openTicketsCount) OPEN", color: VaultTheme.cyan)
                    } else {
                        StatusPill(title: "RESOLVED", color: VaultTheme.emerald)
                    }
                }

                // Middle Metric
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(appState.openTicketsCount)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text(appState.openTicketsCount == 1 ? "Active Ticket" : "Active Tickets")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(VaultTheme.textMuted)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(VaultTheme.textFaint)
                }

                Divider().background(VaultTheme.line)

                // Bottom Ticket Preview
                if let tkt = latestTicket {
                    HStack(spacing: 8) {
                        Text(tkt.ticketNumber)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(VaultTheme.accentBright)
                        Text(tkt.subject)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(VaultTheme.textMuted)
                            .lineLimit(1)
                        Spacer()
                        Text(tkt.status.title)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(tkt.status.color)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundColor(VaultTheme.emerald)
                        Text("No active tickets. All systems running smooth.")
                            .font(.system(size: 11))
                            .foregroundColor(VaultTheme.textMuted)
                    }
                }
            }
            .obsidianCard(cornerRadius: 14, padding: 14)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}
