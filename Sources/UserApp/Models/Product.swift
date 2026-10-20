import Foundation

public struct Product: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var category: String
    public var provider: String
    public var target: String
    public var price: Double
    public var setupFee: Double
    public var billingCycle: String
    public var vcpu: Int
    public var ramGB: Int
    public var diskGB: Int
    public var trafficTB: Int
    public var location: String
    public var isPopular: Bool
    public var specsSummary: String

    enum CodingKeys: String, CodingKey {
        case id, name, category, provider, target, price, cost, stock, hidden
        case setupFee = "setup_fee"
        case billingCycle = "billing_cycle"
        case vcpu, location
        case ramGB = "ram_gb"
        case diskGB = "disk_gb"
        case trafficTB = "traffic_tb"
        case isPopular = "is_popular"
        case specs
    }

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        provider: String = "hetzner_cloud",
        target: String = "vps",
        price: Double,
        setupFee: Double = 0.0,
        billingCycle: String = "monthly",
        vcpu: Int = 0,
        ramGB: Int = 0,
        diskGB: Int = 0,
        trafficTB: Int = 0,
        location: String = "Frankfurt (fsn1)",
        isPopular: Bool = false,
        specsSummary: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.provider = provider
        self.target = target
        self.price = price
        self.setupFee = setupFee
        self.billingCycle = billingCycle
        self.vcpu = vcpu
        self.ramGB = ramGB
        self.diskGB = diskGB
        self.trafficTB = trafficTB
        self.location = location
        self.isPopular = isPopular
        self.specsSummary = specsSummary ?? (vcpu > 0 ? "\(vcpu) vCPU • \(ramGB) GB RAM • \(diskGB) GB NVMe" : location)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID
        if let u = try? container.decode(UUID.self, forKey: .id) {
            self.id = u
        } else if let s = try? container.decode(String.self, forKey: .id), let u = UUID(uuidString: s) {
            self.id = u
        } else {
            self.id = UUID()
        }

        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Cloud Product"
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "General"
        self.provider = (try? container.decode(String.self, forKey: .provider)) ?? "vaultscope"
        self.target = (try? container.decode(String.self, forKey: .target)) ?? "cloud"

        // Price: handle Double or String decimal ("8.40")
        if let p = try? container.decode(Double.self, forKey: .price) {
            self.price = p
        } else if let s = try? container.decode(String.self, forKey: .price), let p = Double(s) {
            self.price = p
        } else {
            self.price = 0.0
        }

        // Setup Fee
        if let sf = try? container.decode(Double.self, forKey: .setupFee) {
            self.setupFee = sf
        } else if let s = try? container.decode(String.self, forKey: .setupFee), let sf = Double(s) {
            self.setupFee = sf
        } else {
            self.setupFee = 0.0
        }

        self.billingCycle = (try? container.decode(String.self, forKey: .billingCycle)) ?? "monthly"

        // Parse specs dictionary or string if present
        var specsLoc: String? = nil
        var specsSummaryStr: String? = nil
        var parsedDisk: Int = 0

        if let rawSpecs = try? container.decode([String: String].self, forKey: .specs) {
            specsLoc = rawSpecs["location"]
            if let st = rawSpecs["storage"] {
                specsSummaryStr = st
            } else if let proto = rawSpecs["protocols"] {
                specsSummaryStr = proto
            }
            if let storageGbStr = rawSpecs["storage_gb"], let gb = Int(storageGbStr) {
                parsedDisk = gb
            }
        } else if let rawString = try? container.decode(String.self, forKey: .specs) {
            specsSummaryStr = rawString
        }

        self.location = (try? container.decode(String.self, forKey: .location)) ?? specsLoc ?? "Europe (EU)"

        self.vcpu = (try? container.decode(Int.self, forKey: .vcpu)) ?? 0
        self.ramGB = (try? container.decode(Int.self, forKey: .ramGB)) ?? 0
        let directDisk = (try? container.decode(Int.self, forKey: .diskGB)) ?? 0
        self.diskGB = directDisk > 0 ? directDisk : parsedDisk
        self.trafficTB = (try? container.decode(Int.self, forKey: .trafficTB)) ?? 0

        // Popular
        if let pop = try? container.decode(Bool.self, forKey: .isPopular) {
            self.isPopular = pop
        } else if let popInt = try? container.decode(Int.self, forKey: .isPopular) {
            self.isPopular = (popInt != 0)
        } else {
            self.isPopular = false
        }

        if let explicitSummary = specsSummaryStr, !explicitSummary.isEmpty {
            self.specsSummary = explicitSummary
        } else if self.vcpu > 0 {
            self.specsSummary = "\(self.vcpu) vCPU • \(self.ramGB) GB RAM • \(self.diskGB) GB NVMe"
        } else if self.diskGB > 0 {
            self.specsSummary = "\(self.diskGB) GB Storage • \(self.location)"
        } else {
            self.specsSummary = self.category
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(provider, forKey: .provider)
        try container.encode(target, forKey: .target)
        try container.encode(price, forKey: .price)
        try container.encode(setupFee, forKey: .setupFee)
        try container.encode(billingCycle, forKey: .billingCycle)
        try container.encode(vcpu, forKey: .vcpu)
        try container.encode(ramGB, forKey: .ramGB)
        try container.encode(diskGB, forKey: .diskGB)
        try container.encode(trafficTB, forKey: .trafficTB)
        try container.encode(location, forKey: .location)
        try container.encode(isPopular, forKey: .isPopular)
    }

    public var formattedPrice: String {
        return String(format: "€%.2f / mo", price)
    }

    public var grossPrice: Double {
        return price * 1.19
    }

    public var formattedGrossPrice: String {
        return String(format: "€%.2f / mo", grossPrice)
    }

    public var formattedPriceBreakdown: String {
        return String(format: "€%.2f net + 19%% VAT", price)
    }
}
