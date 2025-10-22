import Foundation

protocol GitHubServiceProtocol: Sendable {
    func fetchReviewRequestedPRs() async throws -> [PullRequest]
}

// MARK: - Demo Mode Support
extension UserDefaults {
  static let demoModeKey = "isDemoMode"

  var isDemoMode: Bool {
    get { bool(forKey: Self.demoModeKey) }
    set { set(newValue, forKey: Self.demoModeKey) }
  }
}

final class GitHubService: GitHubServiceProtocol, Sendable {
    static let shared = GitHubService()

    init() {}

    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        guard let token = KeychainManager.getToken() else {
            throw GitHubError.tokenNotConfigured
        }

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

// MARK: - Demo Mode Service
final class DemoGitHubService: GitHubServiceProtocol, Sendable {
  static let shared = DemoGitHubService()

  private init() {}

  func fetchReviewRequestedPRs() async throws -> [PullRequest] {
    try await Task.sleep(for: .seconds(0.5))

    return [
      PullRequest(
        id: 1,
        number: 123,
        title: "Add new authentication flow with OAuth2 support",
        htmlURL: "https://github.com/example/awesome-app/pull/123",
        state: "open",
        user: User(login: "developer1", avatarURL: ""),
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 2)),
        updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
      ),
      PullRequest(
        id: 2,
        number: 456,
        title: "Fix memory leak in background refresh task",
        htmlURL: "https://github.com/example/mobile-client/pull/456",
        state: "open",
        user: User(login: "contributor2", avatarURL: ""),
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 5)),
        updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200))
      ),
      PullRequest(
        id: 3,
        number: 789,
        title: "Update dependencies to latest versions",
        htmlURL: "https://github.com/example/backend-api/pull/789",
        state: "open",
        user: User(login: "maintainer3", avatarURL: ""),
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)),
        updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800))
      ),
      PullRequest(
        id: 4,
        number: 321,
        title: "Implement dark mode support for settings panel",
        htmlURL: "https://github.com/example/ui-components/pull/321",
        state: "open",
        user: User(login: "designer4", avatarURL: ""),
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 3)),
        updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-5400))
      ),
      PullRequest(
        id: 5,
        number: 654,
        title: "Add comprehensive test coverage for API endpoints",
        htmlURL: "https://github.com/example/testing-suite/pull/654",
        state: "open",
        user: User(login: "qa-engineer5", avatarURL: ""),
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 4)),
        updatedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-10800))
      )
    ]
  }
}
