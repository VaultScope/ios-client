import SwiftUI

public struct DashboardSpendWidget: View {
    @EnvironmentObject var appState: AppState
    public let onSelect: () -> Void

    public init(onSelect: @escaping () -> Void) {
        self.onSelect = onSelect
    }

    private var pendingInvoicesCount: Int {
        appState.invoices.filter { $0.status == .pending || $0.status == .overdue }.count
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
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(VaultTheme.accentBright)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CLOUD SPEND")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(VaultTheme.textFaint)
                        Text("Monthly Commitment")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(VaultTheme.textSecondary)
                    }

                    Spacer()

                    if pendingInvoicesCount > 0 {
                        StatusPill(title: "\(pendingInvoicesCount) PENDING", color: VaultTheme.amber)
                    } else {
                        StatusPill(title: "CURRENT", color: VaultTheme.emerald)
                    }
                }

                // Middle Metric
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("€\(String(format: "%.2f", appState.monthlyNetSpend))")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text("/ month net")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(VaultTheme.textMuted)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(VaultTheme.textFaint)
                }

                Divider().background(VaultTheme.line)

                // Bottom Details Strip
                HStack {
                    Text("Gross: €\(String(format: "%.2f", appState.monthlyGrossSpend)) (incl. 19% VAT)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(VaultTheme.textMuted)

                    Spacer()

                    Text("SEPA & Cards")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)
                }
            }
            .obsidianCard(cornerRadius: 14, padding: 14)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}
