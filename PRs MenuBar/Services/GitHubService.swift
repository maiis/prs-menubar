import Foundation
import OSLog

/// GitHub API service implementation
/// Uses GitHub GraphQL API v4 to fetch pull requests where the current user is a requested reviewer
/// API Documentation: https://docs.github.com/en/graphql
final class GitHubService: GitServiceProtocol, Sendable {
    static let shared = GitHubService()

    // MARK: - Properties
    private let token: String?

    nonisolated init(token: String? = nil) {
        self.token = token
    }

    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        AppLogger.network
            .info("GitHub: Starting PR fetch (filterDrafts: \(filterDrafts), excludedLabels: \(excludedLabels.count))")

        guard let token else {
            AppLogger.error.error("GitHub: No token configured")
            throw GitServiceError.tokenNotConfigured
        }

        let pageSize = 100

        var searchQuery = "is:pr is:open review-requested:@me"

        if filterDrafts {
            searchQuery += " -draft:true"
        }

        for label in excludedLabels where !label.isEmpty {
            // Escape quotes in label names and wrap in quotes to handle spaces/emojis
            let escapedLabel = label.replacingOccurrences(of: "\"", with: "\\\"")
            searchQuery += " -label:\"\(escapedLabel)\""
        }

        let graphqlEscapedQuery = searchQuery
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let graphqlQuery = """
        {
          search(query: "\(graphqlEscapedQuery)", type: ISSUE, first: \(pageSize)) {
            nodes {
              ... on PullRequest {
                id
                number
                title
                url
                state
                isDraft
                createdAt
                updatedAt
                author {
                  login
                  avatarUrl
                }
                labels(first: 100) {
                  nodes {
                    name
                  }
                }
              }
            }
          }
        }
        """

        let graphqlBody: [String: Any] = ["query": graphqlQuery]
        let jsonData = try JSONSerialization.data(withJSONObject: graphqlBody)

        guard let url = URL(string: "https://api.github.com/graphql") else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)

        try validateHTTPResponse(response)
        if let rateLimit = extractRateLimitInfo(response) {
            if let remaining = rateLimit.remaining, let limit = rateLimit.limit {
                AppLogger.network.debug("GitHub: Rate limit \(remaining)/\(limit)")
            }
            if let remaining = rateLimit.remaining, remaining < 10 {
                AppLogger.network.warning("GitHub: Low rate limit remaining: \(remaining)")
            }
            if let remaining = rateLimit.remaining, remaining == 0 {
                AppLogger.error.error("GitHub: Rate limit exceeded, reset: \(String(describing: rateLimit.reset))")
                throw GitServiceError.rateLimited(resetDate: rateLimit.reset)
            }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            AppLogger.error.error("GitHub: Failed to parse JSON response")
            throw GitServiceError.invalidResponse
        }

        if let errors = json["errors"] as? [[String: Any]], let firstError = errors.first {
            let message = firstError["message"] as? String ?? "Unknown GraphQL error"
            AppLogger.error.error("GitHub: GraphQL error - \(message)")
            throw GitServiceError.networkError(message)
        }

        guard let dataObj = json["data"] as? [String: Any],
              let search = dataObj["search"] as? [String: Any],
              let nodes = search["nodes"] as? [[String: Any]] else
        {
            AppLogger.error.error("GitHub: Invalid response format")
            throw GitServiceError.invalidResponse
        }

        var prs: [PullRequest] = []
        for node in nodes {
            guard let number = node["number"] as? Int,
                  let title = node["title"] as? String,
                  let url = node["url"] as? String,
                  let state = node["state"] as? String,
                  let createdAt = node["createdAt"] as? String,
                  let updatedAt = node["updatedAt"] as? String,
                  let author = node["author"] as? [String: Any],
                  let authorLogin = author["login"] as? String else
            {
                let prIdentifier = node["number"] as? Int ?? node["id"] as? Int
                AppLogger.network.warning("GitHub: Skipped PR due to missing fields (PR #\(prIdentifier ?? -1))")
                continue
            }

            let id = node["id"] as? String ?? "github-pr-\(number)"
            let isDraft = node["isDraft"] as? Bool ?? false

            var labels: [String] = []
            if let labelsData = node["labels"] as? [String: Any],
               let labelNodes = labelsData["nodes"] as? [[String: Any]]
            {
                labels = labelNodes.compactMap { $0["name"] as? String }
            }

            prs.append(PullRequest(
                id: id,
                number: number,
                title: title,
                htmlURL: url,
                state: state.lowercased(),
                isDraft: isDraft,
                user: User(login: authorLogin),
                createdAt: createdAt,
                updatedAt: updatedAt,
                labels: labels
            ))
        }

        AppLogger.network.info("GitHub: Fetched \(prs.count) PRs")
        return prs
    }
}
