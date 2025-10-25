import Foundation

enum GitServiceError: LocalizedError, Sendable {
    case tokenNotConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case forbidden
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .tokenNotConfigured:
            "Access token not found. Please restart the app to configure your token."
        case .invalidURL:
            "Invalid API URL."
        case .invalidResponse:
            "Invalid response from API."
        case .unauthorized:
            "Unauthorized. Please check your access token."
        case .rateLimited:
            "API rate limit exceeded. Try again later."
        case .forbidden:
            "Access forbidden. Check token permissions."
        case let .httpError(statusCode):
            "HTTP error: \(statusCode)"
        }
    }
}
