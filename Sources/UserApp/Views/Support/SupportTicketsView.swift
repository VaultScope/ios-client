import SwiftUI
import UIKit

public struct SupportTicketsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: String = "ALL"
    @State private var showNewTicketSheet: Bool = false

    private let filterOptions = ["ALL", "OPEN", "RESOLVED"]

    private var filteredTickets: [Ticket] {
        switch selectedFilter {
        case "OPEN": return appState.tickets.filter { $0.status != .closed }
        case "RESOLVED": return appState.tickets.filter { $0.status == .closed }
        default: return appState.tickets
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Header SLA & Engineer Access Banner
                    headerStatsCard

                    // MARK: - Filter Bar
                    filterBar

                    // MARK: - Tickets List
                    if filteredTickets.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 12)], spacing: 12) {
                            ForEach(filteredTickets) { ticket in
                                NavigationLink {
                                    TicketDetailView(ticketId: ticket.id)
                                } label: {
                                    ticketCard(ticket: ticket)
                                }
                                .buttonStyle(.plain)
                                .hoverEffect(.highlight)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewTicketSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption.weight(.bold))
                            Text("New Ticket")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(VaultTheme.accent)
                        .clipShape(Capsule())
                    }
                }
            }
            .refreshable {
                await appState.refresh()
            }
            .sheet(isPresented: $showNewTicketSheet) {
                NewTicketSheet()
            }
        }
    }

    // MARK: - Header Stats Card
    private var headerStatsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Direct access to VaultScope infrastructure engineers.")
                    .font(.caption)
                    .foregroundColor(VaultTheme.textMuted)
                Spacer()
                Image(systemName: "lifepreserver.fill")
                    .foregroundColor(VaultTheme.accentBright)
                    .font(.subheadline)
            }

            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(appState.openTicketsCount > 0 ? VaultTheme.accentBright : VaultTheme.emerald)
                        .frame(width: 6, height: 6)
                    Text("\(appState.openTicketsCount) open")
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundColor(VaultTheme.textPrimary)
                }

                if appState.waitingCustomerTicketsCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(VaultTheme.amber)
                            .frame(width: 6, height: 6)
                        Text("\(appState.waitingCustomerTicketsCount) awaiting your reply")
                            .font(.caption.weight(.semibold).monospaced())
                            .foregroundColor(VaultTheme.amber)
                    }
                }
            }
        }
        .obsidianCard(cornerRadius: 12, padding: 12)
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

            Text("\(filteredTickets.count) Tickets")
                .font(.caption2.monospaced())
                .foregroundColor(VaultTheme.textFaint)
        }
    }

    // MARK: - Ticket Card
    private func ticketCard(ticket: Ticket) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ticket.ticketNumber)
                    .font(.caption2.monospaced())
                    .foregroundColor(VaultTheme.accentBright)

                Spacer()

                StatusPill(title: ticket.status.title, color: ticket.status.color)
            }

            Text(ticket.subject)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(VaultTheme.textPrimary)
                .lineLimit(2)

            HStack {
                Text(ticket.category.capitalized)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(VaultTheme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(VaultTheme.subtle)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                Spacer()

                Text(ticket.formattedDate)
                    .font(.caption2)
                    .foregroundColor(VaultTheme.textFaint)
            }
        }
        .obsidianCard(cornerRadius: 12, padding: 12)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32))
                .foregroundColor(VaultTheme.textFaint)
            Text(appState.tickets.isEmpty ? "No Support Tickets" : "No Matching Tickets")
                .font(.headline)
                .foregroundColor(VaultTheme.textPrimary)
            Text(appState.tickets.isEmpty
                 ? "Need technical assistance or have a billing inquiry? Open a ticket to reach our 24/7 engineering team."
                 : "No tickets match the selected filter.")
                .font(.caption)
                .foregroundColor(VaultTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button {
                showNewTicketSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("Open Support Ticket")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(VaultTheme.accent)
                .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .obsidianCard(cornerRadius: 14, padding: 32)
        .padding(.top, 16)
    }
}
