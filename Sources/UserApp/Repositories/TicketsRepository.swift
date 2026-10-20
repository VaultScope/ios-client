import Foundation

public struct TicketWithMessagesWrapper: Decodable, Sendable {
    public let ticket: Ticket
    public let messages: [TicketMessage]
}

public actor TicketsRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func fetchTickets() async throws -> [Ticket] {
        return try await client.request(Endpoint.tickets)
    }

    public func fetchTicketDetail(id: UUID) async throws -> Ticket {
        let endpoint = Endpoint.ticketDetail(id: id)
        if let wrapped: TicketWithMessagesWrapper = try? await client.request(endpoint) {
            var t = wrapped.ticket
            t.messages = wrapped.messages
            return t
        }
        return try await client.request(endpoint)
    }

    public func createTicket(
        subject: String,
        content: String,
        category: String,
        priority: String,
        relatedServiceId: UUID? = nil
    ) async throws {
        let lower = category.lowercased()
        let cleanCategory: String
        if lower.contains("abuse") || lower.contains("security") {
            cleanCategory = "abuse"
        } else if lower.contains("dmca") || lower.contains("legal") {
            cleanCategory = "dmca"
        } else {
            cleanCategory = "support"
        }

        let endpoint = Endpoint.createTicket(
            subject: subject,
            content: content,
            category: cleanCategory,
            priority: priority.lowercased(),
            relatedServiceId: relatedServiceId
        )
        try await client.requestVoid(endpoint)
    }

    public func replyTicket(id: UUID, content: String) async throws {
        let endpoint = Endpoint.replyTicket(id: id, content: content)
        try await client.requestVoid(endpoint)
    }
}
