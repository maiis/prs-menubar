import Foundation

enum GitServiceError: LocalizedError, Sendable {
    case tokenNotConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited(resetDate: Date?)
    case forbidden
    case httpError(statusCode: Int)
    case networkError(String)
    case insufficientPermissions(String)

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
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "API rate limit exceeded. Resets at \(formatter.string(from: resetDate))."
            }
            return "API rate limit exceeded. Try again later."
        case .forbidden:
            return "Access forbidden. Check token permissions."
        case let .httpError(statusCode):
            return "HTTP error: \(statusCode)"
        case let .networkError(error):
            return "Network error: \(error)"
        case let .insufficientPermissions(details):
            return "Insufficient permissions: \(details)"
        }
    }
}
