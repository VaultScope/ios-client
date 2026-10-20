import SwiftUI
import UIKit

public struct DeployCatalogView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: String = "ALL"
    @State private var configuringProduct: Product?

    private let categories = ["ALL", "VPS", "DEDICATED", "ODP", "SFTP"]

    private var filteredProducts: [Product] {
        if selectedCategory == "ALL" {
            return appState.products
        }
        return appState.products.filter { p in
            let cat = p.category.lowercased()
            switch selectedCategory {
            case "VPS":
                return cat == "vps" || cat == "cloud"
            case "DEDICATED":
                return cat == "ds" || cat == "dedicated" || cat == "bare-metal"
            case "ODP":
                return cat == "odp" || cat == "ocd"
            case "SFTP":
                return cat == "storage" || cat == "sftp" || p.name.lowercased().contains("sftp")
            default:
                return true
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Category Filter Bar
                    categoryFilterBar

                    // Products List
                    if appState.products.isEmpty {
                        loadingView
                    } else if filteredProducts.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredProducts) { product in
                                productCard(product: product)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationTitle("Deploy Infrastructure")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await appState.refresh()
            }
            .sheet(item: $configuringProduct) { prod in
                DeployConfiguratorSheet(product: prod)
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

    // MARK: - Product Card
    private func productCard(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(product.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(VaultTheme.textPrimary)

                        if product.isPopular {
                            Text("POPULAR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(VaultTheme.amber)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(VaultTheme.amber.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.location)
                        .font(.caption)
                        .foregroundColor(VaultTheme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.formattedGrossPrice)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text(product.formattedPriceBreakdown)
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textFaint)
                }
            }

            Divider().background(VaultTheme.line)

            // Specs
            if product.vcpu > 0 {
                HStack(spacing: 12) {
                    Label("\(product.vcpu) vCPU", systemImage: "cpu")
                    Label("\(product.ramGB) GB RAM", systemImage: "memorychip")
                    Label("\(product.diskGB) GB NVMe", systemImage: "internaldrive")
                    Label("\(product.trafficTB) TB", systemImage: "arrow.up.arrow.down")
                }
                .font(.caption2.monospaced())
                .foregroundColor(VaultTheme.textMuted)
            } else {
                Text(product.specsSummary)
                    .font(.caption2.monospaced())
                    .foregroundColor(VaultTheme.textMuted)
            }

            // Action Button
            Button {
                configuringProduct = product
            } label: {
                HStack {
                    Text("Configure & Deploy")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(VaultTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .obsidianCard(cornerRadius: 14, padding: 14)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(VaultTheme.accentBright)
            Text("Loading available plans from VaultScope...")
                .font(.caption)
                .foregroundColor(VaultTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .obsidianCard(cornerRadius: 14, padding: 32)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 32))
                .foregroundColor(VaultTheme.textFaint)
            Text("No Plans in Category")
                .font(.headline)
                .foregroundColor(VaultTheme.textPrimary)
            Text("No active catalog plans match the selected category filter.")
                .font(.caption)
                .foregroundColor(VaultTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .obsidianCard(cornerRadius: 14, padding: 32)
    }
}
