import SwiftUI

// MARK: - iPadOS Native Navigation Sidebar
public struct iPadSidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding public var selectedTab: Int
    @Binding public var showAccountSheet: Bool
    @Binding public var showDeploySheet: Bool

    public init(
        selectedTab: Binding<Int>,
        showAccountSheet: Binding<Bool>,
        showDeploySheet: Binding<Bool>
    ) {
        self._selectedTab = selectedTab
        self._showAccountSheet = showAccountSheet
        self._showDeploySheet = showDeploySheet
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Brand Header
            sidebarBrandHeader
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 12)

            Divider()
                .background(VaultTheme.line)

            // MARK: - Navigation Items
            ScrollView {
                VStack(spacing: 4) {
                    sidebarNavItem(
                        tag: 0,
                        title: "Overview",
                        icon: "square.grid.2x2.fill",
                        badge: nil,
                        shortcut: "1"
                    )

                    sidebarNavItem(
                        tag: 1,
                        title: "Infrastructure",
                        icon: "server.rack",
                        badge: appState.activeServices.isEmpty ? nil : "\(appState.activeServices.count)",
                        shortcut: "2"
                    )

                    sidebarNavItem(
                        tag: 2,
                        title: "Deploy Catalog",
                        icon: "plus.circle.fill",
                        badge: nil,
                        shortcut: "3"
                    )

                    sidebarNavItem(
                        tag: 3,
                        title: "Invoices & Billing",
                        icon: "creditcard.fill",
                        badge: appState.invoices.filter { $0.status == .pending || $0.status == .overdue }.isEmpty ? nil : "\(appState.invoices.filter { $0.status == .pending || $0.status == .overdue }.count)",
                        shortcut: "4"
                    )

                    sidebarNavItem(
                        tag: 4,
                        title: "Support Tickets",
                        icon: "lifepreserver.fill",
                        badge: appState.openTicketsCount > 0 ? "\(appState.openTicketsCount)" : nil,
                        shortcut: "5"
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 14)

                // Quick Action Bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUICK ACTIONS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    Button {
                        showDeploySheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                            Text("Deploy New Instance")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(VaultTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.lift)
                    .padding(.horizontal, 12)

                    Button {
                        Task { await appState.refresh() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.bold))
                            Text("Refresh Telemetry")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("⌘R")
                                .font(.caption2.monospaced())
                                .foregroundColor(VaultTheme.textFaint)
                        }
                        .foregroundColor(VaultTheme.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(VaultTheme.subtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .padding(.horizontal, 12)
                }
            }

            Spacer()

            // MARK: - Footer & User Profile
            Divider()
                .background(VaultTheme.line)

            sidebarFooterProfile
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(VaultTheme.card)
        }
        .background(VaultTheme.obsidian.ignoresSafeArea())
    }

    // MARK: - Brand Header
    private var sidebarBrandHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let path = Bundle.module.path(forResource: "LogoPicture", ofType: "png") ?? Bundle.module.path(forResource: "logo-image", ofType: "png"),
                   let uiImage = UIImage(contentsOfFile: path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                } else {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundColor(VaultTheme.accentBright)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("VaultScope")
                        .font(.headline.weight(.bold))
                        .foregroundColor(VaultTheme.textPrimary)
                    Text("iPadOS Enterprise Edition")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)
                }

                Spacer()
            }

            // Connection indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isBackendOnline ? VaultTheme.emerald : VaultTheme.amber)
                    .frame(width: 7, height: 7)

                Text(appState.isBackendOnline ? "api.vaultscope.de (Live)" : "Checking API Gateway...")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(VaultTheme.textMuted)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(VaultTheme.subtle)
            .clipShape(Capsule())
        }
    }

    // MARK: - Nav Item Button
    private func sidebarNavItem(
        tag: Int,
        title: String,
        icon: String,
        badge: String?,
        shortcut: KeyEquivalent
    ) -> some View {
        let isSelected = (selectedTab == tag)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = tag
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? VaultTheme.accentBright : VaultTheme.textMuted)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? VaultTheme.textPrimary : VaultTheme.textMuted)

                Spacer()

                if let badgeText = badge {
                    Text(badgeText)
                        .font(.caption2.weight(.bold).monospaced())
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(VaultTheme.accent)
                        .clipShape(Capsule())
                }

                Text("⌘\(String(shortcut.character))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(isSelected ? VaultTheme.accentBright.opacity(0.8) : VaultTheme.textFaint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? VaultTheme.accentSubtle
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? VaultTheme.accentBright.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .keyboardShortcut(shortcut, modifiers: .command)
    }

    // MARK: - Footer Profile Row
    private var sidebarFooterProfile: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(VaultTheme.accentSubtle)
                    .frame(width: 38, height: 38)

                Text(appState.customer.name.prefix(1).uppercased().isEmpty ? "V" : String(appState.customer.name.prefix(1)).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundColor(VaultTheme.accentBright)
            }

            VStack(alignment: .leading, spacing: 2) {
                let username = appState.customer.username
                Text(username.isEmpty ? "VaultScope User" : "@\(username)")
                    .font(.caption.weight(.bold).monospaced())
                    .foregroundColor(VaultTheme.textPrimary)
                    .lineLimit(1)

                let email = appState.customer.email
                Text(email.isEmpty ? "client@vaultscope.de" : email)
                    .font(.caption2)
                    .foregroundColor(VaultTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button {
                    showAccountSheet = true
                } label: {
                    Label("Account & Security", systemImage: "slider.horizontal.3")
                }

                if appState.isBiometricsEnabled {
                    Button {
                        appState.lockApp()
                    } label: {
                        Label("Lock Screen", systemImage: "lock.shield.fill")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(VaultTheme.textMuted)
                    .padding(4)
            }
            .hoverEffect(.highlight)
        }
    }
}
