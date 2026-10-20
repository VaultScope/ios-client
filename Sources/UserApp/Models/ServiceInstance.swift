import Foundation
import SwiftUI

public enum ServiceStatus: String, Codable, CaseIterable, Sendable, Hashable {
    case running = "running"
    case pending = "pending"
    case suspended = "suspended"
    case stopped = "stopped"
    case terminated = "terminated"

    public var title: String {
        switch self {
        case .running: return "RUNNING"
        case .pending: return "PROVISIONING"
        case .suspended: return "SUSPENDED"
        case .stopped: return "STOPPED"
        case .terminated: return "TERMINATED"
        }
    }

    public var color: Color {
        switch self {
        case .running: return VaultTheme.emerald
        case .pending: return VaultTheme.amber
        case .suspended: return VaultTheme.rose
        case .stopped: return VaultTheme.textMuted
        case .terminated: return VaultTheme.rose
        }
    }

    public var icon: String {
        switch self {
        case .running: return "bolt.fill"
        case .pending: return "hourglass"
        case .suspended: return "exclamationmark.triangle.fill"
        case .stopped: return "stop.circle.fill"
        case .terminated: return "xmark.octagon.fill"
        }
    }
}

public struct ServiceInstance: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var customerId: UUID?
    public var productId: UUID
    public var name: String
    public var hostname: String
    public var status: ServiceStatus
    public var category: String
    public var providerType: String
    public var providerResourceId: String?
    public var sftpPassword: String?
    public var ip: String
    public var ipv6: String
    public var datacenter: String
    public var osImage: String
    public var specs: String
    public var price: Double
    public var nextDue: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var cancelAtPeriodEnd: Bool
    public var isTrial: Bool
    public var uptimeHours: Int
    public var currentCpuPercent: Double
    public var currentMemoryPercent: Double
    public var currentDiskPercent: Double
    public var bandwidthUsedGB: Double
    public var bandwidthLimitGB: Double

    enum CodingKeys: String, CodingKey {
        case id, name, hostname, status, ip, ipv6, datacenter, specs, price, category
        case customerId = "customer_id"
        case productId = "product_id"
        case providerType = "provider_type"
        case providerResourceId = "provider_resource_id"
        case osImage = "os_image"
        case nextDue = "next_due"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case isTrial = "is_trial"
        case uptimeHours = "uptime_hours"
        case currentCpuPercent = "current_cpu_percent"
        case currentMemoryPercent = "current_memory_percent"
        case currentDiskPercent = "current_disk_percent"
        case bandwidthUsedGB = "bandwidth_used_gb"
        case bandwidthLimitGB = "bandwidth_limit_gb"
        case config
    }

    public init(
        id: UUID = UUID(),
        customerId: UUID? = nil,
        productId: UUID = UUID(),
        name: String,
        hostname: String,
        status: ServiceStatus = .running,
        category: String = "vps",
        providerType: String = "hetzner_cloud",
        providerResourceId: String? = nil,
        sftpPassword: String? = nil,
        ip: String,
        ipv6: String = "2a01:4f8:1c1c::1",
        datacenter: String = "Frankfurt, DE (fsn1)",
        osImage: String = "Ubuntu 24.04 LTS",
        specs: String = "Cloud Instance",
        price: Double = 0.0,
        nextDue: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        cancelAtPeriodEnd: Bool = false,
        isTrial: Bool = false,
        uptimeHours: Int = 0,
        currentCpuPercent: Double = 10.0,
        currentMemoryPercent: Double = 35.0,
        currentDiskPercent: Double = 15.0,
        bandwidthUsedGB: Double = 0.0,
        bandwidthLimitGB: Double = 20000.0
    ) {
        self.id = id
        self.customerId = customerId
        self.productId = productId
        self.name = name
        self.hostname = hostname
        self.status = status
        self.category = category
        self.providerType = providerType
        self.providerResourceId = providerResourceId
        self.sftpPassword = sftpPassword
        self.ip = ip
        self.ipv6 = ipv6
        self.datacenter = datacenter
        self.osImage = osImage
        self.specs = specs
        self.price = price
        self.nextDue = nextDue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cancelAtPeriodEnd = cancelAtPeriodEnd
        self.isTrial = isTrial
        self.uptimeHours = uptimeHours
        self.currentCpuPercent = currentCpuPercent
        self.currentMemoryPercent = currentMemoryPercent
        self.currentDiskPercent = currentDiskPercent
        self.bandwidthUsedGB = bandwidthUsedGB
        self.bandwidthLimitGB = bandwidthLimitGB
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let str = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: str) {
            self.id = uuid
        } else {
            self.id = UUID()
        }

        self.customerId = try? container.decode(UUID.self, forKey: .customerId)

        if let pUuid = try? container.decode(UUID.self, forKey: .productId) {
            self.productId = pUuid
        } else if let str = try? container.decode(String.self, forKey: .productId), let uuid = UUID(uuidString: str) {
            self.productId = uuid
        } else {
            self.productId = UUID()
        }

        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Server Instance"
        self.hostname = (try? container.decode(String.self, forKey: .hostname)) ?? "srv.vaultscope.net"
        self.status = (try? container.decode(ServiceStatus.self, forKey: .status)) ?? .running
        self.ip = (try? container.decode(String.self, forKey: .ip)) ?? ""
        self.ipv6 = (try? container.decode(String.self, forKey: .ipv6)) ?? ""
        self.datacenter = (try? container.decode(String.self, forKey: .datacenter)) ?? "Europe (EU)"

        let prov = (try? container.decode(String.self, forKey: .providerType)) ?? "vps"
        self.providerType = prov
        self.providerResourceId = try? container.decode(String.self, forKey: .providerResourceId)

        // Try extracting OS and SFTP info from config if present
        var extractedOs: String? = nil
        var extractedPass: String? = nil
        if let configDict = try? container.decode([String: String].self, forKey: .config) {
            extractedOs = configDict["os_template"] ?? configDict["os"]
            extractedPass = configDict["password"] ?? configDict["sftp_password"]
        }
        self.sftpPassword = extractedPass
        self.osImage = (try? container.decode(String.self, forKey: .osImage)) ?? extractedOs ?? "Linux"
        self.specs = (try? container.decode(String.self, forKey: .specs)) ?? "Cloud Compute Instance"

        let cat = try? container.decode(String.self, forKey: .category)
        if let cat = cat, !cat.isEmpty {
            self.category = cat
        } else if prov.lowercased() == "sftp" || self.name.lowercased().contains("sftp") || self.hostname.lowercased().contains("sftp") {
            self.category = "storage"
        } else {
            self.category = "vps"
        }

        if let p = try? container.decode(Double.self, forKey: .price) {
            self.price = p
        } else if let s = try? container.decode(String.self, forKey: .price), let p = Double(s) {
            self.price = p
        } else {
            self.price = 0.0
        }

        self.cancelAtPeriodEnd = (try? container.decode(Bool.self, forKey: .cancelAtPeriodEnd)) ?? false
        self.isTrial = (try? container.decode(Bool.self, forKey: .isTrial)) ?? false
        self.uptimeHours = (try? container.decode(Int.self, forKey: .uptimeHours)) ?? 0
        self.currentCpuPercent = (try? container.decode(Double.self, forKey: .currentCpuPercent)) ?? (self.status == .running ? 14.5 : 0.0)
        self.currentMemoryPercent = (try? container.decode(Double.self, forKey: .currentMemoryPercent)) ?? (self.status == .running ? 38.0 : 0.0)
        self.currentDiskPercent = (try? container.decode(Double.self, forKey: .currentDiskPercent)) ?? 15.0
        self.bandwidthUsedGB = (try? container.decode(Double.self, forKey: .bandwidthUsedGB)) ?? 0.0
        self.bandwidthLimitGB = (try? container.decode(Double.self, forKey: .bandwidthLimitGB)) ?? 20000.0

        func parseDate(_ s: String) -> Date? {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = isoFractional.date(from: s) { return d }
            let isoStandard = ISO8601DateFormatter()
            if let d = isoStandard.date(from: s) { return d }
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
            if let d = df.date(from: s) { return d }
            df.dateFormat = "yyyy-MM-dd"
            return df.date(from: s)
        }

        if let d = try? container.decode(Date.self, forKey: .createdAt) {
            self.createdAt = d
        } else if let s = try? container.decode(String.self, forKey: .createdAt), let d = parseDate(s) {
            self.createdAt = d
        } else {
            self.createdAt = Date()
        }

        if let d = try? container.decode(Date.self, forKey: .updatedAt) {
            self.updatedAt = d
        } else if let s = try? container.decode(String.self, forKey: .updatedAt), let d = parseDate(s) {
            self.updatedAt = d
        } else {
            self.updatedAt = self.createdAt
        }

        if let d = try? container.decode(Date.self, forKey: .nextDue) {
            self.nextDue = d
        } else if let s = try? container.decode(String.self, forKey: .nextDue), let d = parseDate(s) {
            self.nextDue = d
        } else {
            self.nextDue = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(customerId, forKey: .customerId)
        try container.encode(productId, forKey: .productId)
        try container.encode(name, forKey: .name)
        try container.encode(hostname, forKey: .hostname)
        try container.encode(status, forKey: .status)
        try container.encode(category, forKey: .category)
        try container.encode(providerType, forKey: .providerType)
        try container.encodeIfPresent(providerResourceId, forKey: .providerResourceId)
        try container.encode(ip, forKey: .ip)
        try container.encode(ipv6, forKey: .ipv6)
        try container.encode(datacenter, forKey: .datacenter)
        try container.encode(osImage, forKey: .osImage)
        try container.encode(specs, forKey: .specs)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(nextDue, forKey: .nextDue)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(cancelAtPeriodEnd, forKey: .cancelAtPeriodEnd)
        try container.encode(isTrial, forKey: .isTrial)
        try container.encode(uptimeHours, forKey: .uptimeHours)
        try container.encode(currentCpuPercent, forKey: .currentCpuPercent)
        try container.encode(currentMemoryPercent, forKey: .currentMemoryPercent)
        try container.encode(currentDiskPercent, forKey: .currentDiskPercent)
        try container.encode(bandwidthUsedGB, forKey: .bandwidthUsedGB)
        try container.encode(bandwidthLimitGB, forKey: .bandwidthLimitGB)
    }

    // MARK: - Category Helpers
    public var isSftp: Bool {
        providerType.lowercased() == "sftp" ||
        category.lowercased() == "storage" ||
        category.lowercased() == "sftp" ||
        name.lowercased().contains("sftp") ||
        hostname.lowercased().contains("sftp")
    }

    public var categoryTitle: String {
        if isSftp { return "SFTP Storage Vault" }
        let c = category.lowercased()
        if c == "ds" || c == "dedicated" { return "Dedicated Server" }
        if c == "odp" || c == "ocd" { return "ODP Platform" }
        return "Cloud VPS"
    }

    public var categoryIcon: String {
        if isSftp { return "folder.badge.gearshape" }
        let c = category.lowercased()
        if c == "ds" || c == "dedicated" { return "harddrive.fill" }
        if c == "odp" || c == "ocd" { return "cpu" }
        return "server.rack"
    }

    // MARK: - Price Helpers (Matching Web VAT Breakdown)
    public var grossPrice: Double {
        return price * 1.19
    }

    public var formattedGrossPrice: String {
        return String(format: "€%.2f / mo", grossPrice)
    }

    public var formattedPriceBreakdown: String {
        return String(format: "€%.2f net + 19%% VAT", price)
    }

    // MARK: - SFTP & SSH Connection Commands
    public var sshCommand: String {
        return ip.isEmpty ? "Pending IP assignment" : "ssh root@\(ip)"
    }

    public var sftpPort: Int {
        return 2022
    }

    public var sftpUsername: String {
        if let rid = providerResourceId, !rid.isEmpty { return rid }
        return "vs_\(id.uuidString.prefix(8).lowercased())"
    }

    public var sftpCommand: String {
        let host = hostname.isEmpty ? (ip.isEmpty ? "sftp.vaultscope.de" : ip) : hostname
        return "sftp -P \(sftpPort) \(sftpUsername)@\(host)"
    }

    public var productName: String {
        return name
    }

    public var formattedNextDue: String {
        guard let due = nextDue else { return "Auto-renew active" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: due)
    }

    public var uptimeString: String {
        let days = uptimeHours / 24
        let hours = uptimeHours % 24
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        return "\(hours)h"
    }
}
