import SwiftUI
import UIKit

// UIActivityViewController wrapper for SwiftUI
public struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

public struct InvoiceDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    public let invoiceId: UUID
    @State private var isPaying: Bool = false
    @State private var isDownloadingPdf: Bool = false
    @State private var pdfURL: URL? = nil
    @State private var showShareSheet: Bool = false

    private var invoice: Invoice? {
        appState.invoices.first(where: { $0.id == invoiceId })
    }

    public init(invoiceId: UUID) {
        self.invoiceId = invoiceId
    }

    public var body: some View {
        Group {
            if let inv = invoice {
                List {
                    Section("Invoice Details") {
                        HStack {
                            Text("Invoice Number")
                            Spacer()
                            Text(inv.invoiceNumber)
                                .font(.subheadline.monospaced())
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Status")
                            Spacer()
                            StatusPill(title: inv.status.title, color: inv.status.color)
                        }

                        if !inv.issueDate.isEmpty {
                            HStack {
                                Text("Issue Date")
                                Spacer()
                                Text(inv.issueDate)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if !inv.dueDate.isEmpty {
                            HStack {
                                Text("Due Date")
                                Spacer()
                                Text(inv.dueDate)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if !inv.lineItems.isEmpty {
                        Section("Itemized Charges") {
                            ForEach(inv.lineItems) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.description)
                                            .font(.subheadline.weight(.medium))
                                        Text("Qty: \(item.quantity) × €\(String(format: "%.2f", item.unitPrice))")
                                            .font(.caption.monospaced())
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(String(format: "€%.2f", item.total))
                                        .font(.subheadline.monospaced())
                                }
                            }
                        }
                    }

                    Section("Summary Breakdown") {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(inv.formattedSubtotal)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("MwSt (19% German VAT)")
                            Spacer()
                            Text(inv.formattedTax)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Total Amount")
                                .font(.headline)
                            Spacer()
                            Text(inv.formattedTotal)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }

                    // PDF Download Section
                    Section("Document Export") {
                        Button {
                            downloadPdf(inv: inv)
                        } label: {
                            HStack {
                                Label("Download Official PDF Invoice", systemImage: "arrow.down.doc.fill")
                                Spacer()
                                if isDownloadingPdf {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(isDownloadingPdf)
                    }

                    if inv.status == .pending || inv.status == .overdue {
                        Section {
                            Button {
                                payNow()
                            } label: {
                                if isPaying {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Text("Processing Payment...")
                                        Spacer()
                                    }
                                } else {
                                    Text("Pay Now (\(inv.formattedTotal))")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VaultTheme.cyan)
                            .disabled(isPaying)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(inv.invoiceNumber)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showShareSheet) {
                    if let url = pdfURL {
                        ActivityView(activityItems: [url])
                    }
                }
            } else {
                ContentUnavailableView("Invoice Not Found", systemImage: "doc.text")
            }
        }
    }

    private func downloadPdf(inv: Invoice) {
        isDownloadingPdf = true
        Task {
            do {
                let data = try await appState.downloadInvoicePdf(invoiceId: inv.id)
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent("Invoice-\(inv.invoiceNumber).pdf")
                try data.write(to: fileURL)

                self.pdfURL = fileURL
                self.isDownloadingPdf = false
                self.showShareSheet = true
                appState.showNotification("PDF invoice generated.")
            } catch {
                self.isDownloadingPdf = false
                appState.showNotification("Failed to load PDF: \(error.localizedDescription)")
            }
        }
    }

    private func payNow() {
        isPaying = true
        appState.payInvoice(invoiceId: invoiceId)
        isPaying = false
    }
}
