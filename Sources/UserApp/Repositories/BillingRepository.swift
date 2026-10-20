import Foundation

public actor BillingRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func fetchInvoices() async throws -> [Invoice] {
        return try await client.request(Endpoint.invoices)
    }

    public func downloadInvoicePdf(id: UUID) async throws -> Data {
        return try await client.requestData(Endpoint.invoicePdf(id: id))
    }

    public func payInvoice(id: UUID) async throws {
        try await client.requestVoid(Endpoint.payInvoice(id: id))
    }

    public func fetchBillingInfo() async throws -> BillingInfo {
        do {
            return try await client.request(Endpoint.billing)
        } catch {
            return BillingInfo()
        }
    }
}
