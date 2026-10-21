import SwiftUI

public struct DashboardTelemetryWidget: View {
    @EnvironmentObject var appState: AppState

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                ZStack {
                    Circle()
                        .fill(VaultTheme.accentSubtle)
                        .frame(width: 32, height: 32)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(VaultTheme.accentBright)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("LIVE TELEMETRY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)
                    Text("Global Backbone & Compute")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(VaultTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(VaultTheme.emerald)
                        .frame(width: 6, height: 6)
                    Text("LIVE 1s")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.emerald)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(VaultTheme.subtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(VaultTheme.emerald.opacity(0.3), lineWidth: 1)
                )
            }

            // Dual Mini Metric Strip
            HStack(spacing: 12) {
                MetricMiniGraph(
                    title: "Throughput",
                    currentValue: String(format: "%.1f", appState.currentNetworkMbps),
                    data: appState.networkHistory,
                    color: VaultTheme.cyan,
                    unit: "Mbps"
                )

                MetricMiniGraph(
                    title: "Compute Load",
                    currentValue: "\(Int(appState.cpuHistory.last ?? 0.0))",
                    data: appState.cpuHistory,
                    color: VaultTheme.accentBright,
                    unit: "%"
                )
            }
        }
        .obsidianCard(cornerRadius: 14, padding: 14)
    }
}
