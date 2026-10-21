import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
public struct VaultScopeWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetSnapshotData

    public init(date: Date = Date(), snapshot: WidgetSnapshotData = WidgetSnapshotData()) {
        self.date = date
        self.snapshot = snapshot
    }
}

// MARK: - Timeline Provider
public struct VaultScopeTimelineProvider: TimelineProvider {
    public typealias Entry = VaultScopeWidgetEntry

    public init() {}

    public func placeholder(in context: Context) -> VaultScopeWidgetEntry {
        VaultScopeWidgetEntry(
            date: Date(),
            snapshot: WidgetSnapshotData(
                runningServers: 4,
                totalServers: 4,
                openTickets: 1,
                waitingTickets: 1,
                monthlySpend: 42.50
            )
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (VaultScopeWidgetEntry) -> Void) {
        let snap = WidgetSyncManager.shared.loadSnapshot()
        let entry = VaultScopeWidgetEntry(date: Date(), snapshot: snap)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VaultScopeWidgetEntry>) -> Void) {
        let snap = WidgetSyncManager.shared.loadSnapshot()
        let entry = VaultScopeWidgetEntry(date: Date(), snapshot: snap)
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 1. Server Fleet Widget View
public struct ServerFleetWidgetEntryView: View {
    public var entry: VaultScopeTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        ZStack {
            VaultTheme.obsidian

            VStack(alignment: .leading, spacing: 8) {
                // Header Row
                HStack {
                    ZStack {
                        Circle()
                            .fill(VaultTheme.accentSubtle)
                            .frame(width: 24, height: 24)
                        Image(systemName: "server.rack")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(VaultTheme.accentBright)
                    }

                    Text("FLEET")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)

                    Spacer()

                    Circle()
                        .fill(entry.snapshot.runningServers > 0 ? VaultTheme.emerald : VaultTheme.amber)
                        .frame(width: 7, height: 7)
                }

                Spacer()

                // Big Counter
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.runningServers)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text("/ \(entry.snapshot.totalServers)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(VaultTheme.textMuted)
                }

                Text(entry.snapshot.runningServers == entry.snapshot.totalServers && entry.snapshot.totalServers > 0
                     ? "All Systems Operational"
                     : "Instances Online")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(entry.snapshot.runningServers == entry.snapshot.totalServers ? VaultTheme.emerald : VaultTheme.textMuted)
                    .lineLimit(1)

                if family == .systemMedium {
                    Divider().background(VaultTheme.line)
                    HStack {
                        Label("Spend: €\(String(format: "%.2f", entry.snapshot.monthlySpend))/mo", systemImage: "creditcard")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(VaultTheme.textFaint)
                        Spacer()
                        Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 9))
                            .foregroundColor(VaultTheme.textFaint)
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - 2. Support Ticket Widget View
public struct SupportTicketWidgetEntryView: View {
    public var entry: VaultScopeTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        ZStack {
            VaultTheme.obsidian

            VStack(alignment: .leading, spacing: 8) {
                // Header Row
                HStack {
                    ZStack {
                        Circle()
                            .fill(VaultTheme.accentSubtle)
                            .frame(width: 24, height: 24)
                        Image(systemName: "lifepreserver.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(VaultTheme.accentBright)
                    }

                    Text("SUPPORT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)

                    Spacer()

                    if entry.snapshot.waitingTickets > 0 {
                        Text("\(entry.snapshot.waitingTickets) ACTION")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(VaultTheme.purple)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(entry.snapshot.openTickets)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(VaultTheme.textPrimary)

                    Text("Active")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(VaultTheme.textMuted)
                }

                if entry.snapshot.waitingTickets > 0 {
                    Text("Engineer Waiting on You")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(VaultTheme.purple)
                        .lineLimit(1)
                } else if entry.snapshot.openTickets == 0 {
                    Text("All Tickets Resolved")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(VaultTheme.emerald)
                        .lineLimit(1)
                } else {
                    Text("In Progress with Engineers")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(VaultTheme.cyan)
                        .lineLimit(1)
                }

                if family == .systemMedium {
                    Divider().background(VaultTheme.line)
                    HStack {
                        Text("24/7 Enterprise Cloud SLA Guaranteed")
                            .font(.system(size: 9))
                            .foregroundColor(VaultTheme.textFaint)
                        Spacer()
                        Text("Realtime Sync")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(VaultTheme.accentBright)
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Widget Configurations
public struct ServerFleetWidget: Widget {
    public let kind: String = "VaultScopeServerFleetWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaultScopeTimelineProvider()) { entry in
            ServerFleetWidgetEntryView(entry: entry)
                .containerBackground(VaultTheme.obsidian, for: .widget)
        }
        .configurationDisplayName("Server Fleet Status")
        .description("Glanceable operational status of your cloud infrastructure instances.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

public struct SupportTicketWidget: Widget {
    public let kind: String = "VaultScopeSupportTicketWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaultScopeTimelineProvider()) { entry in
            SupportTicketWidgetEntryView(entry: entry)
                .containerBackground(VaultTheme.obsidian, for: .widget)
        }
        .configurationDisplayName("Support & Tickets")
        .description("Track active infrastructure support tickets and engineer responses.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
