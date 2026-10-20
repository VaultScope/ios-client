import SwiftUI
import UIKit

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

public struct InvoicesListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: String = "ALL"
    @State private var downloadingInvoiceId: UUID? = nil
    @State private var pdfShareItem: IdentifiableURL? = nil

    private let filterOptions = ["ALL", "PAID", "PENDING"]

    private var filteredInvoices: [Invoice] {
        switch selectedFilter {
        case "PAID": return appState.invoices.filter { $0.status == .paid }
        case "PENDING": return appState.invoices.filter { $0.status == .pending || $0.status == .overdue }
        default: return appState.invoices
        }
    }

    private var pendingTotal: Double {
        appState.invoices.filter { $0.status == .pending || $0.status == .overdue }.reduce(0.0) { $0 + $1.total }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Top Summary Strip
                    topSummaryStrip

                    // MARK: - Filter Bar
                    filterBar

                    // MARK: - Invoices Stream
                    if filteredInvoices.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredInvoices) { invoice in
                                NavigationLink {
                                    InvoiceDetailView(invoiceId: invoice.id)
                                } label: {
                                    invoiceRow(invoice: invoice)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationTitle("Billing & Invoices")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await appState.refresh()
            }
            .sheet(item: $pdfShareItem) { item in
                ActivityView(activityItems: [item.url])
            }
        }
    }

    // MARK: - Top Summary Strip
    private var topSummaryStrip: some View {
        HStack(spacing: 12) {
            // Card 1: Balance
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT BALANCE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(VaultTheme.textFaint)

                Text(pendingTotal > 0 ? String(format: "€%.2f", pendingTotal) : "€0.00")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(pendingTotal > 0 ? VaultTheme.amber : VaultTheme.textPrimary)

                Text(pendingTotal > 0 ? "Payment due" : "No outstanding balance")
                    .font(.caption2)
                    .foregroundColor(pendingTotal > 0 ? VaultTheme.amber : VaultTheme.emerald)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .obsidianCard(cornerRadius: 12, padding: 12)

            // Card 2: Payment Method
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("PAYMENT METHOD")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)
                    Spacer()
                    Image(systemName: "creditcard.fill")
                        .font(.caption2)
                        .foregroundColor(VaultTheme.accentBright)
                }

                Text("Stripe Auto-Pay")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(VaultTheme.textPrimary)

                Text(appState.customer.vatId.isEmpty ? "Standard VAT (19%)" : "Reverse Charge (0%)")
                    .font(.caption2)
                    .foregroundColor(VaultTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .obsidianCard(cornerRadius: 12, padding: 12)
        }
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(filterOptions, id: \.self) { filter in
                    let isSelected = (selectedFilter == filter)
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.capitalized)
                            .font(.caption.weight(isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? VaultTheme.textPrimary : VaultTheme.textMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? VaultTheme.subtle : VaultTheme.card)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(isSelected ? VaultTheme.accentBright.opacity(0.6) : VaultTheme.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Text("\(filteredInvoices.count) Invoices")
                .font(.caption2.monospaced())
                .foregroundColor(VaultTheme.textFaint)
        }
    }

    // MARK: - Invoice Row
    private func invoiceRow(invoice: Invoice) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 18))
                .foregroundColor(VaultTheme.accentBright)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(invoice.invoiceNumber)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    StatusPill(title: invoice.status.title, color: invoice.status.color)
                }

                Text(invoice.issueDate.isEmpty ? "Issued recently" : invoice.issueDate)
                    .font(.caption2)
                    .foregroundColor(VaultTheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(invoice.formattedTotal)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(VaultTheme.textPrimary)

                Button {
                    downloadPdf(invoice: invoice)
                } label: {
                    HStack(spacing: 3) {
                        if downloadingInvoiceId == invoice.id {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.down.doc")
                                .font(.caption2)
                            Text("PDF")
                                .font(.caption2.weight(.medium))
                        }
                    }
                    .foregroundColor(VaultTheme.accentBright)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(VaultTheme.subtle)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .obsidianCard(cornerRadius: 12, padding: 12)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(VaultTheme.textFaint)
            Text("No Invoices Found")
                .font(.headline)
                .foregroundColor(VaultTheme.textPrimary)
            Text(appState.invoices.isEmpty ? "No invoices have been issued for this account yet." : "No invoices match filter '\(selectedFilter)'.")
                .font(.caption)
                .foregroundColor(VaultTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .obsidianCard(cornerRadius: 14, padding: 32)
        .padding(.top, 16)
    }

    private func downloadPdf(invoice: Invoice) {
        downloadingInvoiceId = invoice.id
        Task {
            do {
                let data = try await appState.downloadInvoicePdf(invoiceId: invoice.id)
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("Invoice-\(invoice.invoiceNumber).pdf")
                try data.write(to: fileURL)
                downloadingInvoiceId = nil
                pdfShareItem = IdentifiableURL(url: fileURL)
            } catch {
                downloadingInvoiceId = nil
                appState.showNotification("Failed to download PDF: \(error.localizedDescription)")
            }
        }
    }
}
