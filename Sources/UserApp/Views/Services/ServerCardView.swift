import SwiftUI
import UIKit

public struct ServerCardView: View {
    public let service: ServiceInstance
    @State private var isIpRevealed: Bool = false
    @State private var copiedKey: String? = nil
    @State private var showSftpClient: Bool = false

    public init(service: ServiceInstance) {
        self.service = service
    }

    private var maskedIp: String {
        guard !service.ip.isEmpty else { return "Pending Assignment" }
        if isIpRevealed { return service.ip }
        let parts = service.ip.split(separator: ".")
        if parts.count == 4 {
            return "\(parts[0]).•••.•••.•••"
        }
        return "\(service.ip.prefix(4))••••"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Category Icon, Hostname, Status Pill
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: service.categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(VaultTheme.accentBright)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(service.status.color)
                            .frame(width: 6, height: 6)

                        Text(service.hostname)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(VaultTheme.textPrimary)
                    }

                    Text(service.name)
                        .font(.caption)
                        .foregroundColor(VaultTheme.textMuted)
                }

                Spacer()

                StatusPill(title: service.status.title, color: service.status.color)
            }

            Divider().background(VaultTheme.line)

            // Middle: Connectivity / SFTP details or Specs
            if service.isSftp {
                sftpDetailsRow
            } else {
                computeDetailsRow
            }

            // Bottom: Pricing & Due Date
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.formattedGrossPrice)
                        .font(.subheadline.weight(.semibold).monospaced())
                        .foregroundColor(VaultTheme.textPrimary)

                    Text(service.formattedPriceBreakdown)
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                }

                Spacer()

                if let due = service.nextDue {
                    Text("Due \(due, style: .date)")
                        .font(.caption2.monospaced())
                        .foregroundColor(VaultTheme.textFaint)
                } else {
                    Text("Auto-renew active")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textFaint)
                }
            }

            // Resource Gauges if running compute
            if service.status == .running && !service.isSftp {
                HStack(spacing: 12) {
                    ResourceGauge(label: "CPU", value: service.currentCpuPercent, color: VaultTheme.cyan)
                    ResourceGauge(label: "RAM", value: service.currentMemoryPercent, color: VaultTheme.purple)
                    ResourceGauge(label: "DISK", value: service.currentDiskPercent, color: VaultTheme.amber)
                }
                .padding(.top, 2)
            }
        }
        .obsidianCard(cornerRadius: 14, padding: 14)
        .sheet(isPresented: $showSftpClient) {
            SftpClientView(service: service)
        }
    }

    // MARK: - Compute Details Row
    private var computeDetailsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // IP Address with reveal/mask toggle & copy
                HStack(spacing: 5) {
                    Image(systemName: "network")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)

                    Text(maskedIp)
                        .font(.caption.monospaced())
                        .foregroundColor(VaultTheme.textPrimary)

                    Button {
                        isIpRevealed.toggle()
                    } label: {
                        Image(systemName: isIpRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 11))
                            .foregroundColor(VaultTheme.textFaint)
                    }
                    .buttonStyle(.plain)

                    if !service.ip.isEmpty {
                        Button {
                            UIPasteboard.general.string = service.ip
                            copiedKey = "ip"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                copiedKey = nil
                            }
                        } label: {
                            Image(systemName: copiedKey == "ip" ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                                .foregroundColor(copiedKey == "ip" ? VaultTheme.emerald : VaultTheme.textFaint)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Datacenter location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.accentBright)
                    Text(service.datacenter)
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                }
            }

            // Specs
            Text(service.specs)
                .font(.caption2.monospaced())
                .foregroundColor(VaultTheme.textFaint)
        }
    }

    // MARK: - SFTP Details Row
    private var sftpDetailsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Text("User:")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                    Text(service.sftpUsername)
                        .font(.caption.monospaced())
                        .foregroundColor(VaultTheme.textPrimary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Port:")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                    Text("\(service.sftpPort)")
                        .font(.caption.monospaced())
                        .foregroundColor(VaultTheme.accentBright)
                }
            }

            // Quick Copy SFTP command
            Button {
                UIPasteboard.general.string = service.sftpCommand
                copiedKey = "sftp"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copiedKey = nil
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "terminal")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                    Text(service.sftpCommand)
                        .font(.caption2.monospaced())
                        .foregroundColor(VaultTheme.textMuted)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: copiedKey == "sftp" ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                        .foregroundColor(copiedKey == "sftp" ? VaultTheme.emerald : VaultTheme.accentBright)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(VaultTheme.subtle)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(VaultTheme.line, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                showSftpClient = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.gearshape.fill")
                        .font(.caption2)
                    Text("Open Built-in SFTP Explorer")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundColor(VaultTheme.accentBright)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(VaultTheme.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Resource Mini Gauge
struct ResourceGauge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(VaultTheme.textFaint)
                Spacer()
                Text(String(format: "%.0f%%", value))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(VaultTheme.textMuted)
            }

            ProgressView(value: min(max(value, 0), 100), total: 100)
                .tint(color)
                .scaleEffect(y: 0.6)
        }
    }
}
