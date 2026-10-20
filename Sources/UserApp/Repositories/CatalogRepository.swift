import Foundation

public struct OrderResponse: Decodable, Sendable {
    public let serviceId: UUID?
    public let jobId: UUID?
    public let status: String?

    enum CodingKeys: String, CodingKey {
        case status
        case serviceId = "service_id"
        case jobId = "job_id"
    }
}

public actor CatalogRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func fetchProducts() async throws -> [Product] {
        return try await client.request(Endpoint.catalog)
    }

    public func fetchOptions() async throws -> StorefrontOptions {
        do {
            return try await client.request(Endpoint.options)
        } catch {
            return StorefrontOptions()
        }
    }

    public func placeOrder(productId: UUID, hostname: String? = nil, partnerSlug: String? = nil) async throws -> UUID {
        let endpoint = Endpoint.placeOrder(productId: productId, hostname: hostname, partnerSlug: partnerSlug)
        let resp: OrderResponse = try await client.request(endpoint)
        return resp.serviceId ?? UUID()
    }

    public func createPaymentIntent(productId: UUID) async throws -> String? {
        let endpoint = Endpoint.createPaymentIntent(productId: productId)
        let resp: PaymentIntentResponse = try await client.request(endpoint)
        return resp.client_secret ?? resp.clientSecret
    }
}
