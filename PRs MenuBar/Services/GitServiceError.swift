import Foundation

enum GitServiceError: LocalizedError, Sendable {
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

    var errorDescription: String? {
        switch self {
        case .tokenNotConfigured:
            return "Access token not found. Please restart the app to configure your token."
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Invalid response from API."
        case .unauthorized:
            return "Unauthorized. Please check your access token."
        case let .rateLimited(resetDate):
            if let resetDate {
                let minutes = Int(ceil(resetDate.timeIntervalSinceNow / 60))
                if minutes <= 0 {
                    return "API rate limit exceeded. Try again now."
                } else if minutes == 1 {
                    return "API rate limit exceeded. Retry in 1 minute."
                } else {
                    return "API rate limit exceeded. Retry in \(minutes) minutes."
                }
            }
            return "API rate limit exceeded. Try again later."
        case .forbidden:
            return "Access forbidden. Check token permissions."
        case let .httpError(statusCode):
            return "HTTP error: \(statusCode)"
        case let .insufficientPermissions(details):
            return "Insufficient permissions: \(details)"
        case .noInternet:
            return "No internet connection. Check your network settings."
        case .timeout:
            return "Request timed out. Check your connection or try again."
        case .dnsFailure:
            return "Cannot reach server. Check your DNS or network settings."
        case .connectionFailed:
            return "Connection failed. The server may be unreachable."
        case .sslError:
            return "SSL/TLS error. Check your network security settings."
        case let .networkError(error):
            return "Network error: \(error)"
        }
    }

    /// Returns true if this error is transient and the operation should be retried
    var isTransient: Bool {
        switch self {
        case .timeout, .connectionFailed, .dnsFailure, .noInternet:
            true
        case .rateLimited:
            true
        case let .httpError(statusCode):
            // Server errors are transient, client errors are not
            statusCode >= 500
        default:
            false
        }
    }

    /// Returns true if this error indicates the user is offline
    var isOfflineError: Bool {
        switch self {
        case .noInternet:
            true
        default:
            false
        }
    }
}
