import Foundation

final class GitHubService: Sendable {
    static let shared = GitHubService()

    private init() {}

    // Fetch PRs where the authenticated user is requested as a reviewer
    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        guard let token = KeychainManager.getToken() else {
            throw GitHubError.tokenNotConfigured
        }

        // let query = "is:pr is:open creator:@me"
        let query = "is:pr is:open review-requested:@me"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw GitHubError.invalidURL
        }

        let urlString = "https://api.github.com/search/issues?q=\(encodedQuery)"

        guard let url = URL(string: urlString) else {
            throw GitHubError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw GitHubError.unauthorized
                } else if httpResponse.statusCode == 403 {
                    if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
                       remaining == "0" {
                        throw GitHubError.rateLimited
                    }
                    throw GitHubError.forbidden
                } else {
                    throw GitHubError.httpError(statusCode: httpResponse.statusCode)
                }
            }

            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(GitHubSearchResponse.self, from: data)
            return searchResponse.items
        } catch {
            throw error
        }
    }
}

// MARK: - GitHub Errors
enum GitHubError: LocalizedError {
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
            return "GitHub token not found. Please restart the app to configure your token."
        case .invalidURL:
            return "Invalid GitHub API URL."
        case .invalidResponse:
            return "Invalid response from GitHub API."
        case .unauthorized:
            return "Unauthorized. Please check your GitHub token."
        case .rateLimited:
            return "GitHub API rate limit exceeded. Try again later."
        case .forbidden:
            return "Access forbidden. Check token permissions."
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}
