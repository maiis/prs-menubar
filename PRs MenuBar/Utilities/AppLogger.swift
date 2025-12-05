import Foundation
import OSLog

/// Centralized logging utility for the app using os.Logger
/// Logs are viewable in Console.app by filtering for subsystem: me.maiis.prsmenubar
enum AppLogger {

    // MARK: - Loggers
    /// General app lifecycle and state changes
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Network requests and API calls
    static let network = Logger(subsystem: subsystem, category: "network")

    /// Account management and authentication
    static let auth = Logger(subsystem: subsystem, category: "auth")

    /// Background refresh timer and scheduling
    static let refresh = Logger(subsystem: subsystem, category: "refresh")

    /// Keychain operations
    static let keychain = Logger(subsystem: subsystem, category: "keychain")

    /// Error tracking and failures
    static let error = Logger(subsystem: subsystem, category: "error")

    // MARK: - Constants
    private static let subsystem = "me.maiis.prsmenubar"
}
