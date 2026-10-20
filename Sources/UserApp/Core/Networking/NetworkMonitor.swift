import Foundation
import Network
import Combine

public enum ConnectionType: String, Sendable {
    case wifi = "Wi-Fi"
    case cellular = "Cellular"
    case wired = "Ethernet"
    case offline = "Offline"

    public var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wired: return "cable.connector"
        case .offline: return "wifi.slash"
        }
    }
}

public final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    public static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.vaultscope.networkmonitor", qos: .background)

    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var isCellular: Bool = false
    @Published public private(set) var isExpensive: Bool = false
    @Published public private(set) var connectionType: ConnectionType = .wifi

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = (path.status == .satisfied)
            let cellular = path.isExpensive || path.usesInterfaceType(.cellular)
            let expensive = path.isExpensive

            let type: ConnectionType
            if !connected {
                type = .offline
            } else if path.usesInterfaceType(.wifi) {
                type = .wifi
            } else if path.usesInterfaceType(.cellular) {
                type = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                type = .wired
            } else {
                type = .wifi
            }

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = connected
                self.isCellular = cellular
                self.isExpensive = expensive
                self.connectionType = type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
