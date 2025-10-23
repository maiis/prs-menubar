import Foundation

enum GitHubError: LocalizedError, Sendable {
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
            "GitHub token not found. Please restart the app to configure your token."
        case .invalidURL:
            "Invalid GitHub API URL."
        case .invalidResponse:
            "Invalid response from GitHub API."
        case .unauthorized:
            "Unauthorized. Please check your GitHub token."
        case .rateLimited:
            "GitHub API rate limit exceeded. Try again later."
        case .forbidden:
            "Access forbidden. Check token permissions."
        case let .httpError(statusCode):
            "HTTP error: \(statusCode)"
        }
    }
}
