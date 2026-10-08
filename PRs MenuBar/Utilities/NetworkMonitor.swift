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

    /// Fires after the network transitions from disconnected → connected.
    /// Consumers set this to react to reconnects (e.g. trigger a refresh).
    /// Kept as a single callback (not multi-subscriber) because this singleton has one logical owner.
    var onReconnect: (@MainActor () -> Void)?

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "me.maiis.prsmenubar.networkmonitor")

    // MARK: - Init
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Helpers
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
        AppLogger.network.info("Network monitoring started")
    }

    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied

        if wasConnected != isConnected {
            if isConnected {
                AppLogger.network.info("Network connected")
                onReconnect?()
            } else {
                AppLogger.network.warning("Network disconnected")
            }
        }
    }
}
