import Foundation

enum GitServiceError: LocalizedError, Equatable {
    case tokenNotConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited(resetDate: Date?)
    case forbidden
    case httpError(statusCode: Int)
    case insufficientPermissions(String)

    // Network-specific errors
    case noInternet
    case timeout
    case dnsFailure
    case connectionFailed
    case sslError
    case networkError(String)

    /// User-facing: shown in the menu bar panel and the account list.
    var errorDescription: String? {
        switch self {
        case .tokenNotConfigured, .unauthorized:
            "Your token is invalid or expired. Please update it."
        case .forbidden:
            "Access denied. Please check your token permissions."
        case let .insufficientPermissions(details):
            "Insufficient permissions: \(details)"
        case let .rateLimited(resetDate):
            Self.rateLimitMessage(resetDate)
        case .noInternet:
            "No internet connection. Check your network settings."
        case .timeout:
            "Request timed out. Your connection may be slow or unstable."
        case .dnsFailure:
            "Cannot reach server. Check your DNS or network settings."
        case .connectionFailed:
            "Connection failed. The server may be unreachable."
        case .sslError:
            "SSL error. Check your network security settings or try again."
        case let .httpError(statusCode) where statusCode >= 500:
            "Server error (HTTP \(statusCode)). The service may be temporarily unavailable."
        case let .httpError(statusCode):
            "Unexpected server response (HTTP \(statusCode))."
        case .invalidURL:
            "Invalid server URL."
        case .invalidResponse:
            "Unexpected response from the server. Please try again."
        case let .networkError(message):
            "Network error: \(message)"
        }
    }

    private static func rateLimitMessage(_ resetDate: Date?) -> String {
        guard let resetDate else { return "API rate limit exceeded. Try again later." }
        let minutes = Int(ceil(resetDate.timeIntervalSinceNow / 60))
        return switch minutes {
        case ...0: "API rate limit exceeded. Try again now."
        case 1: "API rate limit exceeded. Retry in 1 minute."
        default: "API rate limit exceeded. Retry in \(minutes) minutes."
        }
    }

    /// True for failures worth an automatic retry. Rate limits are excluded: they don't clear
    /// on the retry's 15s timescale.
    var isTransient: Bool {
        switch self {
        case .timeout, .connectionFailed, .dnsFailure, .noInternet:
            true
        case let .httpError(statusCode):
            statusCode >= 500
        default:
            false
        }
    }

    /// True when the user can fix this by updating their token.
    /// Drives the "Update Token" button in the menu bar error state.
    var requiresTokenUpdate: Bool {
        switch self {
        case .unauthorized, .forbidden, .tokenNotConfigured, .insufficientPermissions:
            true
        default:
            false
        }
    }
}
