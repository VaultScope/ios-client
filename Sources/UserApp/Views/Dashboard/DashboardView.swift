import SwiftUI
import UIKit

public struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    @State private var showAccountSheet: Bool = false
    @State private var showDeploySheet: Bool = false
    @State private var showNewTicketSheet: Bool = false
    @State private var managingServiceId: UUID? = nil
    @State private var selectedSftpService: ServiceInstance? = nil

    private var runningCount: Int {
        appState.services.filter { $0.status == .running }.count
    }

    public init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header Status & Brand Row
                    headerBrandRow

                    // MARK: - 3-Column Metric & Quick Nav Strip
                    metricStrip

                    // MARK: - Deployed Infrastructure Stream
                    deployedInfrastructureStream

                    // MARK: - Built-in SFTP Client
                    sftpStorageVaultSection

                    // MARK: - Recent Audit Activity
                    recentActivitySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    brandToolbarLeading
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button {
                            showDeploySheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                Text("Deploy")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(VaultTheme.accent)
                            .clipShape(Capsule())
                        }

                        Button {
                            showAccountSheet = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
                                .foregroundColor(VaultTheme.textPrimary)
                        }
                    }
                }
            }
            .refreshable {
                await appState.refresh()
            }
            .sheet(isPresented: $showAccountSheet) {
                AccountView()
            }
            .sheet(isPresented: $showDeploySheet) {
                if let first = appState.products.first {
                    DeployConfiguratorSheet(product: first)
                }
            }
            .sheet(isPresented: $showNewTicketSheet) {
                NewTicketSheet()
            }
            .sheet(item: $selectedSftpService) { srv in
                SftpClientView(service: srv)
            }
            .navigationDestination(item: $managingServiceId) { id in
                ServiceDetailView(serviceId: id)
            }
        }
    }

    // MARK: - Toolbar Brand Leading
    private var brandToolbarLeading: some View {
        HStack(spacing: 8) {
            if let path = Bundle.module.path(forResource: "LogoPicture", ofType: "png") ?? Bundle.module.path(forResource: "logo-image", ofType: "png"),
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 22)
            } else if let path = Bundle.module.path(forResource: "Logo", ofType: "png"),
                      let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
            } else {
                Image(systemName: "shield.fill")
                    .foregroundColor(VaultTheme.accentBright)
                    .font(.subheadline)
            }

            Text("VaultScope Client")
                .font(.headline.weight(.semibold))
                .foregroundColor(VaultTheme.textPrimary)
        }
    }

    // MARK: - Header Brand Row
    private var headerBrandRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let username = appState.customer.username
                Text(username.isEmpty ? "@vaultscope" : "@\(username)")
                    .font(.caption2.monospaced())
                    .foregroundColor(VaultTheme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VaultTheme.subtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(VaultTheme.line, lineWidth: 1)
                    )

                Spacer()
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Overview")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(VaultTheme.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        selectedTab = 4 // Support Tab
                    } label: {
                        Text("View tickets")
                            .font(.caption.weight(.medium))
                            .foregroundColor(VaultTheme.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(VaultTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(VaultTheme.line, lineWidth: 1)
                            )
                    }

                    Button {
                        selectedTab = 2 // Deploy Tab
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption2.weight(.bold))
                            Text("Order New")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(VaultTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - 3-Card Metric Strip
    private var metricStrip: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Card 1: Instances
                VStack(alignment: .leading, spacing: 4) {
                    Text("INSTANCES")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)

                    Text(appState.isRefreshing && appState.services.isEmpty
                         ? "—"
                         : "\(appState.activeServices.count) \(appState.activeServices.count == 1 ? "Service" : "Services")")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text("\(runningCount) online")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .obsidianCard(cornerRadius: 12, padding: 14)

                // Card 2: Run Rate
                VStack(alignment: .leading, spacing: 4) {
                    Text("RUN RATE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)

                    Text(appState.monthlyGrossSpend > 0
                         ? String(format: "€%.2f / mo", appState.monthlyGrossSpend)
                         : "€0.00 / mo")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text(appState.monthlyNetSpend > 0
                         ? String(format: "€%.2f net + 19%% VAT", appState.monthlyNetSpend)
                         : "Predictable monthly billing")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .obsidianCard(cornerRadius: 12, padding: 14)
            }

            // Card 3: Quick Navigation
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("QUICK NAVIGATION")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)

                    Spacer()

                    Button {
                        showAccountSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption2)
                            Text("Account")
                                .font(.caption2)
                        }
                        .foregroundColor(VaultTheme.accentBright)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        QuickNavChip(title: "VPS", icon: "server.rack") {
                            selectedTab = 1
                        }

                        QuickNavChip(title: "Dedicated", icon: "harddrive.fill") {
                            selectedTab = 1
                        }

                        QuickNavChip(title: "ODP", icon: "cpu") {
                            selectedTab = 1
                        }

                        QuickNavChip(title: "SFTP", icon: "folder.badge.gearshape") {
                            if let srv = appState.sftpServices.first ?? appState.activeServices.first {
                                selectedSftpService = srv
                            } else {
                                selectedTab = 1
                            }
                        }

                        QuickNavChip(title: "Billing", icon: "creditcard.fill") {
                            selectedTab = 3
                        }

                        QuickNavChip(title: "Support (\(appState.openTicketsCount))", icon: "lifepreserver.fill") {
                            selectedTab = 4
                        }
                    }
                }
            }
            .obsidianCard(cornerRadius: 12, padding: 14)
        }
    }

    // MARK: - Deployed Infrastructure Stream
    private var deployedInfrastructureStream: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deployed Infrastructure")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(VaultTheme.textPrimary)

                Spacer()

                Text("\(appState.activeServices.count) total")
                    .font(.caption2.monospaced())
                    .foregroundColor(VaultTheme.textFaint)
            }

            if appState.activeServices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 32))
                        .foregroundColor(VaultTheme.textFaint)

                    Text("No services yet")
                        .font(.headline)
                        .foregroundColor(VaultTheme.textPrimary)

                    Text("Deploy a Cloud VPS, Dedicated Server, One-Click application, or SFTP storage vault in seconds.")
                        .font(.caption)
                        .foregroundColor(VaultTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Button {
                        selectedTab = 2
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                            Text("Deploy First Service")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(VaultTheme.accent)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .obsidianCard(cornerRadius: 14, padding: 24)
            } else {
                VStack(spacing: 1) {
                    ForEach(appState.activeServices) { service in
                        Button {
                            managingServiceId = service.id
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: service.categoryIcon)
                                    .font(.system(size: 16))
                                    .foregroundColor(VaultTheme.accentBright)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(service.status.color)
                                            .frame(width: 6, height: 6)

                                        Text(service.hostname)
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundColor(VaultTheme.textPrimary)
                                            .lineLimit(1)

                                        Text(service.status.title)
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(VaultTheme.textMuted)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(VaultTheme.subtle)
                                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    }

                                    HStack(spacing: 8) {
                                        Text(service.name)
                                            .font(.caption)
                                            .foregroundColor(VaultTheme.textMuted)
                                            .lineLimit(1)

                                        if !service.ip.isEmpty {
                                            Text("•")
                                                .foregroundColor(VaultTheme.textFaint)
                                            Text(service.ip)
                                                .font(.caption2.monospaced())
                                                .foregroundColor(VaultTheme.textFaint)
                                        }

                                        if let due = service.nextDue {
                                            Text("•")
                                                .foregroundColor(VaultTheme.textFaint)
                                            Text("Due \(due, style: .date)")
                                                .font(.caption2)
                                                .foregroundColor(VaultTheme.textFaint)
                                        }
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(service.formattedGrossPrice)
                                        .font(.caption.weight(.semibold).monospaced())
                                        .foregroundColor(VaultTheme.textPrimary)

                                    HStack(spacing: 2) {
                                        Text("Manage")
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(VaultTheme.accentBright)
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(VaultTheme.accentBright)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(VaultTheme.card)
                        }
                        .buttonStyle(.plain)

                        if service.id != appState.activeServices.last?.id {
                            Divider()
                                .background(VaultTheme.line)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(VaultTheme.line, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Built-in SFTP Storage Section
    @ViewBuilder
    private var sftpStorageVaultSection: some View {
        let sftpSrvs = appState.sftpServices
        let targetService = sftpSrvs.first ?? appState.activeServices.first

        if let srv = targetService {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.gearshape.fill")
                            .foregroundColor(VaultTheme.accentBright)
                        Text("Built-in SFTP Client")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(VaultTheme.textPrimary)
                    }

                    Spacer()

                    Text("Connected Vault")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(VaultTheme.accentSubtle)
                        .foregroundColor(VaultTheme.accentBright)
                        .cornerRadius(4)
                }

                Button {
                    selectedSftpService = srv
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(VaultTheme.accentSubtle)
                                .frame(width: 44, height: 44)
                            Image(systemName: "externaldrive.fill.badge.checkmark")
                                .font(.system(size: 20))
                                .foregroundColor(VaultTheme.accentBright)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(srv.isSftp ? "SFTP Storage Vault: \(srv.name)" : "SFTP File Manager: \(srv.hostname)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(VaultTheme.textPrimary)

                            Text("sftp://\(srv.sftpUsername)@\(srv.hostname.isEmpty ? (srv.ip.isEmpty ? "sftp.vaultscope.de" : srv.ip) : srv.hostname):\(srv.sftpPort)")
                                .font(.caption2.monospaced())
                                .foregroundColor(VaultTheme.textMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Text("Tap to browse files, manage backups & edit configs")
                                .font(.caption2)
                                .foregroundColor(VaultTheme.emerald)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(VaultTheme.textFaint)
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
                .obsidianCard(cornerRadius: 14, padding: 0)
            }
        }
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(VaultTheme.textPrimary)

                Spacer()

                Button {
                    showAccountSheet = true
                } label: {
                    Text("View all logs")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.accentBright)
                }
            }

            if appState.activities.isEmpty {
                Text("No audit events recorded.")
                    .font(.caption)
                    .foregroundColor(VaultTheme.textMuted)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.activities.prefix(5).enumerated()), id: \.element.id) { index, activity in
                        HStack(spacing: 12) {
                            Image(systemName: activity.type.icon)
                                .foregroundColor(activity.type.color)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(VaultTheme.textPrimary)
                                Text(activity.detail)
                                    .font(.caption2)
                                    .foregroundColor(VaultTheme.textMuted)
                            }

                            Spacer()

                            Text(activity.relativeTime)
                                .font(.caption2.monospaced())
                                .foregroundColor(VaultTheme.textFaint)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if index < min(appState.activities.count, 5) - 1 {
                            Divider().background(VaultTheme.line)
                        }
                    }
                }
                .obsidianCard(cornerRadius: 14, padding: 0)
            }
        }
    }
}

// MARK: - Quick Navigation Chip
struct QuickNavChip: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(VaultTheme.accentBright)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(VaultTheme.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(VaultTheme.subtle)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(VaultTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }
}
