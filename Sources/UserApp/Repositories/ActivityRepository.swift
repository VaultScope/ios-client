import Foundation

public actor ActivityRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func fetchActivities() async throws -> [ActivityItem] {
        return try await client.request(Endpoint.activity)
    }
}
