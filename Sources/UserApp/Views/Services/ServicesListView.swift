import SwiftUI
import UIKit

public struct ServicesListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "ALL"
    @State private var selectedStatus: String = "ALL"
    @State private var showDeploySheet: Bool = false
    @State private var copiedText: String? = nil

    private let categories = ["ALL", "VPS", "DEDICATED", "ODP", "SFTP"]
    private let statuses = ["ALL", "RUNNING", "STOPPED"]

    private var filteredServices: [ServiceInstance] {
        appState.services.filter { service in
            // 1. Category Filter
            let matchesCategory: Bool
            switch selectedCategory {
            case "VPS":
                matchesCategory = (!service.isSftp && (service.category.lowercased() == "vps" || service.category.isEmpty))
            case "DEDICATED":
                let c = service.category.lowercased()
                matchesCategory = (c == "ds" || c == "dedicated")
            case "ODP":
                let c = service.category.lowercased()
                matchesCategory = (c == "odp" || c == "ocd")
            case "SFTP":
                matchesCategory = service.isSftp
            default:
                matchesCategory = true
            }

            // 2. Status Filter
            let matchesStatus: Bool
            switch selectedStatus {
            case "RUNNING":
                matchesStatus = (service.status == .running)
            case "STOPPED":
                matchesStatus = (service.status == .stopped || service.status == .suspended)
            default:
                matchesStatus = true
            }

            // 3. Search Query
            if searchText.isEmpty {
                return matchesCategory && matchesStatus
            } else {
                let query = searchText.lowercased()
                return matchesCategory && matchesStatus && (
                    service.name.lowercased().contains(query) ||
                    service.hostname.lowercased().contains(query) ||
                    service.ip.contains(query) ||
                    service.osImage.lowercased().contains(query)
                )
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Category Filter Chips
                    categoryFilterBar

                    // MARK: - Search & Status Filter
                    statusFilterBar

                    // MARK: - Services List / Content
                    if filteredServices.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], spacing: 14) {
                            ForEach(filteredServices) { service in
                                NavigationLink {
                                    ServiceDetailView(serviceId: service.id)
                                } label: {
                                    ServerCardView(service: service)
                                }
                                .buttonStyle(.plain)
                                .hoverEffect(.highlight)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationTitle("Infrastructure")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search hostnames, IPs, or OS...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                }
            }
            .refreshable {
                await appState.refresh()
            }
            .sheet(isPresented: $showDeploySheet) {
                if let first = appState.products.first {
                    DeployConfiguratorSheet(product: first)
                }
            }
        }
    }

    // MARK: - Category Filter Bar
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = (selectedCategory == cat)
                    Button {
                        selectedCategory = cat
                    } label: {
                        HStack(spacing: 6) {
                            if cat == "VPS" {
                                Image(systemName: "server.rack")
                            } else if cat == "DEDICATED" {
                                Image(systemName: "harddrive.fill")
                            } else if cat == "ODP" {
                                Image(systemName: "cpu")
                            } else if cat == "SFTP" {
                                Image(systemName: "folder.badge.gearshape")
                            }

                            Text(cat)
                                .font(.caption.weight(isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? VaultTheme.textPrimary : VaultTheme.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? VaultTheme.subtle : VaultTheme.card)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(isSelected ? VaultTheme.accentBright.opacity(0.6) : VaultTheme.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Status Filter Bar
    private var statusFilterBar: some View {
        HStack {
            Text("\(filteredServices.count) \(filteredServices.count == 1 ? "Instance" : "Instances")")
                .font(.caption.weight(.semibold).monospaced())
                .foregroundColor(VaultTheme.textFaint)

            Spacer()

            Menu {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(statuses, id: \.self) { status in
                        Text(status.capitalized).tag(status)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedStatus == "ALL" ? "All Statuses" : selectedStatus.capitalized)
                        .font(.caption.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(VaultTheme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(VaultTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(VaultTheme.line, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "server.rack")
                .font(.system(size: 36))
                .foregroundColor(VaultTheme.textFaint)

            Text(appState.services.isEmpty ? "No Infrastructure Yet" : "No Matching Instances")
                .font(.headline)
                .foregroundColor(VaultTheme.textPrimary)

            Text(appState.services.isEmpty
                 ? "Deploy high-performance Cloud VPS, Dedicated Bare Metal, or encrypted SFTP storage in seconds."
                 : (searchText.isEmpty ? "No instances match category '\(selectedCategory)' and status '\(selectedStatus)'." : "No instances match query '\(searchText)'."))
                .font(.caption)
                .foregroundColor(VaultTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button {
                showDeploySheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("Deploy New Service")
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
        .obsidianCard(cornerRadius: 14, padding: 32)
        .padding(.top, 20)
    }
}
