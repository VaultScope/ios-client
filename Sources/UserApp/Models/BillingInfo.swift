import Foundation

public struct BillingAddress: Codable, Sendable {
    public var name: String
    public var company: String
    public var line1: String
    public var country: String

    public init(name: String = "", company: String = "", line1: String = "", country: String = "Germany") {
        self.name = name
        self.company = company
        self.line1 = line1
        self.country = country
    }
}

public struct BillingSubscription: Identifiable, Codable, Sendable {
    public var id: String
    public var name: String
    public var description: String
    public var price: String
    public var nextDate: String
    public var cancelAtPeriodEnd: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, price
        case nextDate = "next_date"
        case cancelAtPeriodEnd = "cancel_at_period_end"
    }

    public init(id: String, name: String, description: String, price: String, nextDate: String, cancelAtPeriodEnd: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.nextDate = nextDate
        self.cancelAtPeriodEnd = cancelAtPeriodEnd
    }
}

public struct BillingInfo: Codable, Sendable {
    public var balance: String
    public var nextCharge: String?
    public var status: String
    public var cardLast4: String?
    public var cardExp: String?
    public var address: BillingAddress?
    public var vatId: String?
    public var subscriptions: [BillingSubscription]

    enum CodingKeys: String, CodingKey {
        case balance, status, address
        case nextCharge = "next_charge"
        case cardLast4 = "card_last4"
        case cardExp = "card_exp"
        case vatId = "vat_id"
        case subscriptions
    }

    public init(
        balance: String = "€0.00",
        nextCharge: String? = nil,
        status: String = "No outstanding balance",
        cardLast4: String? = nil,
        cardExp: String? = nil,
        address: BillingAddress? = nil,
        vatId: String? = nil,
        subscriptions: [BillingSubscription] = []
    ) {
        self.balance = balance
        self.nextCharge = nextCharge
        self.status = status
        self.cardLast4 = cardLast4
        self.cardExp = cardExp
        self.address = address
        self.vatId = vatId
        self.subscriptions = subscriptions
    }
}
