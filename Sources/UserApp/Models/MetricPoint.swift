import Foundation

public struct MetricPoint: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let cpuPercent: Double
    public let memoryPercent: Double
    public let diskMBs: Double
    public let networkInMbps: Double
    public let networkOutMbps: Double

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        cpuPercent: Double,
        memoryPercent: Double,
        diskMBs: Double,
        networkInMbps: Double,
        networkOutMbps: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        self.diskMBs = diskMBs
        self.networkInMbps = networkInMbps
        self.networkOutMbps = networkOutMbps
    }
}
