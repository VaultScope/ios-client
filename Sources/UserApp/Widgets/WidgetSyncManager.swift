import Foundation
import WidgetKit

public struct WidgetSnapshotData: Codable, Sendable {
    public let runningServers: Int
    public let totalServers: Int
    public let openTickets: Int
    public let waitingTickets: Int
    public let monthlySpend: Double
    public let lastUpdated: Date

    public init(
        runningServers: Int = 0,
        totalServers: Int = 0,
        openTickets: Int = 0,
        waitingTickets: Int = 0,
        monthlySpend: Double = 0.0,
        lastUpdated: Date = Date()
    ) {
        self.runningServers = runningServers
        self.totalServers = totalServers
        self.openTickets = openTickets
        self.waitingTickets = waitingTickets
        self.monthlySpend = monthlySpend
        self.lastUpdated = lastUpdated
    }
}

public final class WidgetSyncManager: Sendable {
    public static let shared = WidgetSyncManager()

    public static let appGroupSuite = "group.com.vaultscope.client"
    public static let snapshotKey = "vaultscope.widget.snapshot.v1"

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupSuite) ?? UserDefaults.standard
    }

    public func sync(
        runningServers: Int,
        totalServers: Int,
        openTickets: Int,
        waitingTickets: Int,
        monthlySpend: Double
    ) {
        let snapshot = WidgetSnapshotData(
            runningServers: runningServers,
            totalServers: totalServers,
            openTickets: openTickets,
            waitingTickets: waitingTickets,
            monthlySpend: monthlySpend,
            lastUpdated: Date()
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            sharedDefaults.set(data, forKey: Self.snapshotKey)
            UserDefaults.standard.set(data, forKey: Self.snapshotKey)
        }

        // Request Home Screen widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func loadSnapshot() -> WidgetSnapshotData {
        if let data = sharedDefaults.data(forKey: Self.snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshotData.self, from: data) {
            return snapshot
        }
        if let data = UserDefaults.standard.data(forKey: Self.snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetSnapshotData.self, from: data) {
            return snapshot
        }
        return WidgetSnapshotData()
    }
}
