import SwiftUI

public struct DashboardServerWidget: View {
    @EnvironmentObject var appState: AppState
    public let onSelect: () -> Void

    public init(onSelect: @escaping () -> Void) {
        self.onSelect = onSelect
    }

    private var runningCount: Int {
        appState.services.filter { $0.status == .running }.count
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
                        Image(systemName: "server.rack")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(VaultTheme.accentBright)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("SERVER FLEET")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(VaultTheme.textFaint)
                        Text(appState.isAllOperational ? "Operational" : "Degraded")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(appState.isAllOperational ? VaultTheme.emerald : VaultTheme.amber)
                    }

                    Spacer()

                    StatusPill(
                        title: "\(runningCount)/\(appState.activeServices.count) ACTIVE",
                        color: appState.isAllOperational ? VaultTheme.emerald : VaultTheme.amber
                    )
                }

                // Middle Metric
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(appState.activeServices.count)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text(appState.activeServices.count == 1 ? "Cloud Instance" : "Cloud Instances")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(VaultTheme.textMuted)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(VaultTheme.textFaint)
                }

                Divider().background(VaultTheme.line)

                // Bottom Category Strip
                HStack(spacing: 12) {
                    categoryBadge(name: "VPS", count: appState.vpsServices.count, icon: "cpu")
                    categoryBadge(name: "Dedicated", count: appState.dedicatedServices.count, icon: "square.stack.3d.up.fill")
                    categoryBadge(name: "SFTP Vault", count: appState.sftpServices.count, icon: "externaldrive.fill")
                }
            }
            .obsidianCard(cornerRadius: 14, padding: 14)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    private func categoryBadge(name: String, count: Int, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(count > 0 ? VaultTheme.accentBright : VaultTheme.textFaint)
            Text("\(count) \(name)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(count > 0 ? VaultTheme.textSecondary : VaultTheme.textFaint)
        }
    }
}
