import Foundation

public final class TicketSSEClient: @unchecked Sendable {
    private var streamTask: Task<Void, Never>?
    private let ticketId: UUID
    private let baseURL: URL
    private let token: String?
    private let onMessage: @Sendable (TicketMessage) -> Void
    private let onConnectionChange: (@Sendable (Bool) -> Void)?

    public init(
        ticketId: UUID,
        baseURL: URL,
        token: String?,
        onMessage: @escaping @Sendable (TicketMessage) -> Void,
        onConnectionChange: (@Sendable (Bool) -> Void)? = nil
    ) {
        self.ticketId = ticketId
        self.baseURL = baseURL
        self.token = token
        self.onMessage = onMessage
        self.onConnectionChange = onConnectionChange
    }

    public func connect() {
        disconnect()

        streamTask = Task { [weak self] in
            guard let self = self else { return }

            var path = self.baseURL.absoluteString
            if path.hasSuffix("/") { path.removeLast() }
            let fullURLString = "\(path)/api/storefront/tickets/\(self.ticketId.uuidString.lowercased())/events"

            guard let url = URL(string: fullURLString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.setValue("keep-alive", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 300

            if let token = self.token, !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            while !Task.isCancelled {
                do {
                    let sessionConfig = URLSessionConfiguration.default
                    sessionConfig.timeoutIntervalForRequest = 60
                    sessionConfig.timeoutIntervalForResource = 3600
                    let session = URLSession(configuration: sessionConfig)

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        self.onConnectionChange?(false)
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        continue
                    }

                    self.onConnectionChange?(true)

                    var currentEvent = "message"
                    for try await line in bytes.lines {
                        if Task.isCancelled { break }

                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { continue }

                        if trimmed.hasPrefix("event:") {
                            currentEvent = trimmed.dropFirst(6).trimmingCharacters(in: .whitespaces)
                        } else if trimmed.hasPrefix("data:") {
                            let dataString = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                            if currentEvent == "message", let data = dataString.data(using: .utf8) {
                                if let msg = try? JSONDecoder.vaultScope.decode(TicketMessage.self, from: data) {
                                    self.onMessage(msg)
                                }
                            }
                        }
                    }
                } catch {
                    if Task.isCancelled { break }
                    self.onConnectionChange?(false)
                    // Back off before reconnecting
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                }
            }

            self.onConnectionChange?(false)
        }
    }

    public func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        onConnectionChange?(false)
    }

    deinit {
        disconnect()
    }
}
