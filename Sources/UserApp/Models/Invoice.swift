import Foundation
import SwiftUI

public enum InvoiceStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case paid = "paid"
    case pending = "pending"
    case overdue = "overdue"
    case draft = "draft"
    case voidStatus = "void"

    public var title: String {
        switch self {
        case .paid: return "PAID"
        case .pending: return "PENDING"
        case .overdue: return "OVERDUE"
        case .draft: return "DRAFT"
        case .voidStatus: return "VOID"
        }
    }

    public var color: Color {
        switch self {
        case .paid: return VaultTheme.emerald
        case .pending: return VaultTheme.amber
        case .overdue: return VaultTheme.rose
        case .draft: return VaultTheme.cyan
        case .voidStatus: return VaultTheme.textMuted
        }
    }
}

public struct InvoiceLineItem: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var description: String
    public var quantity: Int
    public var unitPrice: Double
    public var total: Double

    enum CodingKeys: String, CodingKey {
        case id, description, quantity, total
        case unitPrice = "unit_price"
    }

    public init(
        id: UUID = UUID(),
        description: String,
        quantity: Int = 1,
        unitPrice: Double,
        total: Double? = nil
    ) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = total ?? (unitPrice * Double(quantity))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let u = try? container.decode(UUID.self, forKey: .id) {
            self.id = u
        } else if let s = try? container.decode(String.self, forKey: .id), let u = UUID(uuidString: s) {
            self.id = u
        } else {
            self.id = UUID()
        }

        self.description = (try? container.decode(String.self, forKey: .description)) ?? "Cloud Hosting Services"
        self.quantity = (try? container.decode(Int.self, forKey: .quantity)) ?? 1

        if let up = try? container.decode(Double.self, forKey: .unitPrice) {
            self.unitPrice = up
        } else if let s = try? container.decode(String.self, forKey: .unitPrice), let up = Double(s) {
            self.unitPrice = up
        } else {
            self.unitPrice = 0.0
        }

        if let t = try? container.decode(Double.self, forKey: .total) {
            self.total = t
        } else if let s = try? container.decode(String.self, forKey: .total), let t = Double(s) {
            self.total = t
        } else {
            self.total = self.unitPrice * Double(self.quantity)
        }
    }
}

public struct Invoice: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var invoiceNumber: String
    public var status: InvoiceStatus
    public var subtotal: Double
    public var taxRate: Double
    public var taxAmount: Double
    public var total: Double
    public var issueDate: String
    public var dueDate: String
    public var paidAt: Date?
    public var notes: String
    public var lineItems: [InvoiceLineItem]

    enum CodingKeys: String, CodingKey {
        case id, status, subtotal, total, notes
        case invoiceNumber = "invoice_number"
        case taxRate = "tax_rate"
        case taxAmount = "tax_amount"
        case issueDate = "issue_date"
        case dueDate = "due_date"
        case paidAt = "paid_at"
        case lineItems = "line_items"
        case items
    }

    public init(
        id: UUID = UUID(),
        invoiceNumber: String,
        status: InvoiceStatus,
        subtotal: Double,
        taxRate: Double = 0.19,
        taxAmount: Double? = nil,
        total: Double? = nil,
        issueDate: String,
        dueDate: String,
        paidAt: Date? = nil,
        notes: String = "Thank you for hosting with VaultScope.",
        lineItems: [InvoiceLineItem] = []
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.status = status
        self.subtotal = subtotal
        self.taxRate = taxRate
        let calculatedTax = taxAmount ?? (subtotal * taxRate)
        self.taxAmount = calculatedTax
        self.total = total ?? (subtotal + calculatedTax)
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.paidAt = paidAt
        self.notes = notes
        self.lineItems = lineItems
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let u = try? container.decode(UUID.self, forKey: .id) {
            self.id = u
        } else if let s = try? container.decode(String.self, forKey: .id), let u = UUID(uuidString: s) {
            self.id = u
        } else {
            self.id = UUID()
        }

        self.invoiceNumber = (try? container.decode(String.self, forKey: .invoiceNumber)) ?? "INV-0000"
        self.status = (try? container.decode(InvoiceStatus.self, forKey: .status)) ?? .pending

        // Subtotal
        if let st = try? container.decode(Double.self, forKey: .subtotal) {
            self.subtotal = st
        } else if let s = try? container.decode(String.self, forKey: .subtotal), let st = Double(s) {
            self.subtotal = st
        } else {
            self.subtotal = 0.0
        }

        // Tax Rate
        if let tr = try? container.decode(Double.self, forKey: .taxRate) {
            self.taxRate = tr
        } else if let s = try? container.decode(String.self, forKey: .taxRate), let tr = Double(s) {
            self.taxRate = tr
        } else {
            self.taxRate = 0.19
        }

        // Tax Amount
        if let ta = try? container.decode(Double.self, forKey: .taxAmount) {
            self.taxAmount = ta
        } else if let s = try? container.decode(String.self, forKey: .taxAmount), let ta = Double(s) {
            self.taxAmount = ta
        } else {
            self.taxAmount = self.subtotal * self.taxRate
        }

        // Total
        if let t = try? container.decode(Double.self, forKey: .total) {
            self.total = t
        } else if let s = try? container.decode(String.self, forKey: .total), let t = Double(s) {
            self.total = t
        } else {
            self.total = self.subtotal + self.taxAmount
        }

        self.issueDate = (try? container.decode(String.self, forKey: .issueDate)) ?? ""
        self.dueDate = (try? container.decode(String.self, forKey: .dueDate)) ?? ""
        self.notes = (try? container.decode(String.self, forKey: .notes)) ?? "VaultScope Enterprise Cloud"

        func parseDate(_ s: String) -> Date? {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: s) { return d }
            let isoStandard = ISO8601DateFormatter()
            return isoStandard.date(from: s)
        }

        if let d = try? container.decode(Date.self, forKey: .paidAt) {
            self.paidAt = d
        } else if let s = try? container.decode(String.self, forKey: .paidAt), let d = parseDate(s) {
            self.paidAt = d
        } else {
            self.paidAt = nil
        }

        if let items = try? container.decode([InvoiceLineItem].self, forKey: .lineItems) {
            self.lineItems = items
        } else if let items = try? container.decode([InvoiceLineItem].self, forKey: .items) {
            self.lineItems = items
        } else {
            self.lineItems = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(invoiceNumber, forKey: .invoiceNumber)
        try container.encode(status, forKey: .status)
        try container.encode(subtotal, forKey: .subtotal)
        try container.encode(taxRate, forKey: .taxRate)
        try container.encode(taxAmount, forKey: .taxAmount)
        try container.encode(total, forKey: .total)
        try container.encode(issueDate, forKey: .issueDate)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(paidAt, forKey: .paidAt)
        try container.encode(notes, forKey: .notes)
        try container.encode(lineItems, forKey: .lineItems)
    }

    public var formattedTotal: String {
        return String(format: "€%.2f", total)
    }

    public var formattedSubtotal: String {
        return String(format: "€%.2f", subtotal)
    }

    public var formattedTax: String {
        return String(format: "€%.2f", taxAmount)
    }
}
