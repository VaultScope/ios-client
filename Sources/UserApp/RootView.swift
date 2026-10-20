import SwiftUI

public struct RootView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: Int = 0
    @State private var isBackgrounded: Bool = false
    @State private var showAccountSheet: Bool = false
    @State private var showDeploySheet: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            Group {
                if appState.isAuthenticated {
                    if horizontalSizeClass == .regular {
                        // MARK: - iPadOS Native Navigation Split View & Sidebar
                        NavigationSplitView {
                            iPadSidebarView(
                                selectedTab: $selectedTab,
                                showAccountSheet: $showAccountSheet,
                                showDeploySheet: $showDeploySheet
                            )
                            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
                        } detail: {
                            Group {
                                switch selectedTab {
                                case 0:
                                    DashboardView(selectedTab: $selectedTab)
                                case 1:
                                    ServicesListView()
                                case 2:
                                    DeployCatalogView()
                                case 3:
                                    InvoicesListView()
                                case 4:
                                    SupportTicketsView()
                                default:
                                    DashboardView(selectedTab: $selectedTab)
                                }
                            }
                        }
                        .navigationSplitViewStyle(.balanced)
                        .sheet(isPresented: $showAccountSheet) {
                            AccountView()
                        }
                        .sheet(isPresented: $showDeploySheet) {
                            if let first = appState.products.first {
                                DeployConfiguratorSheet(product: first)
                            }
                        }
                    } else {
                        // MARK: - iPhone Native Tab View
                        TabView(selection: $selectedTab) {
                            DashboardView(selectedTab: $selectedTab)
                                .tabItem {
                                    Label("Overview", systemImage: "square.grid.2x2.fill")
                                }
                                .tag(0)

                            ServicesListView()
                                .tabItem {
                                    Label("Infrastructure", systemImage: "server.rack")
                                }
                                .tag(1)

                            DeployCatalogView()
                                .tabItem {
                                    Label("Deploy", systemImage: "plus.circle.fill")
                                }
                                .tag(2)

                            InvoicesListView()
                                .tabItem {
                                    Label("Billing", systemImage: "creditcard.fill")
                                }
                                .tag(3)

                            SupportTicketsView()
                                .tabItem {
                                    Label("Support", systemImage: "lifepreserver.fill")
                                }
                                .tag(4)
                        }
                        .tint(VaultTheme.accentBright)
                    }
                } else {
                    LoginView()
                }
            }

            // MARK: - Privacy Shield & Biometric Lock Overlay
            if appState.isAppLocked {
                PrivacyShieldView(
                    biometryType: appState.biometryType,
                    onUnlockRequested: {
                        Task { await appState.authenticateBiometrics() }
                    },
                    onLogoutRequested: {
                        appState.logout()
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            } else if isBackgrounded {
                VaultTheme.obsidian
                    .ignoresSafeArea()
                    .overlay {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(VaultTheme.accentBright.opacity(0.3))
                    }
                    .zIndex(998)
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                // Offline Banner
                if !appState.isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                            .font(.caption2.weight(.bold))
                        Text("Offline — Reconnecting to VaultScope API...")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(VaultTheme.amber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(VaultTheme.subtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(VaultTheme.amber.opacity(0.4), lineWidth: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
                }

                // Toast Notification Banner
                if let bannerMsg = appState.successBannerMessage {
                    BannerToastView(message: bannerMsg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 4)
                        .padding(.horizontal, 16)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.isAuthenticated)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.isAppLocked)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.isConnected)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.successBannerMessage)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                isBackgrounded = true
                appState.lockApp()
            } else if newPhase == .active {
                isBackgrounded = false
                if appState.isAppLocked {
                    Task {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        await appState.authenticateBiometrics()
                    }
                }
            }
        }
        .task {
            if appState.isAppLocked {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await appState.authenticateBiometrics()
            }
        }
    }
}
