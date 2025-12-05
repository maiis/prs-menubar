import Foundation
import Network
import OSLog

@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Properties
    private(set) var isConnected = true
    private(set) var connectionType: ConnectionType = .unknown

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "me.maiis.prsmenubar.networkmonitor")

    enum ConnectionType: Sendable {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    // MARK: - Init
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public API
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
        AppLogger.network.info("Network monitoring started")
    }

    func stopMonitoring() {
        monitor.cancel()
        AppLogger.network.info("Network monitoring stopped")
    }

    // MARK: - Helpers
    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }

        if wasConnected != isConnected {
            if isConnected {
                AppLogger.network.info("Network connected via \(String(describing: self.connectionType))")
            } else {
                AppLogger.network.warning("Network disconnected")
            }
        }
    }
}
