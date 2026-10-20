import Foundation

public actor ServicesRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func fetchServices() async throws -> [ServiceInstance] {
        return try await client.request(Endpoint.services)
    }

    public func fetchService(id: UUID) async throws -> ServiceInstance {
        return try await client.request(Endpoint.serviceDetail(id: id))
    }

    public func start(id: UUID) async throws {
        try await client.requestVoid(Endpoint.startService(id: id))
    }

    public func stop(id: UUID) async throws {
        try await client.requestVoid(Endpoint.stopService(id: id))
    }

    public func restart(id: UUID) async throws {
        try await client.requestVoid(Endpoint.restartService(id: id))
    }

    public func reinstall(id: UUID, os: String) async throws {
        try await client.requestVoid(Endpoint.reinstallService(id: id, os: os))
    }

    public func cancel(id: UUID, mode: String = "period_end", reason: String? = nil, feedback: String? = nil) async throws {
        try await client.requestVoid(Endpoint.cancelService(id: id, mode: mode, reason: reason, feedback: feedback))
    }

    public func uncancel(id: UUID) async throws {
        try await client.requestVoid(Endpoint.uncancelService(id: id))
    }

    public func console(id: UUID) async throws -> String? {
        let resp: ConsoleResponse = try await client.request(Endpoint.console(id: id))
        return resp.url ?? resp.wss_url
    }

    public func delete(id: UUID) async throws {
        try await client.requestVoid(Endpoint.deleteService(id: id))
    }
}
