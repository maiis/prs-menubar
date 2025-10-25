import Foundation

/// GitHub API service implementation
/// Uses GitHub GraphQL API v4 to fetch pull requests where the current user is a requested reviewer
/// API Documentation: https://docs.github.com/en/graphql
final class GitHubService: GitHubServiceProtocol, Sendable {
    static let shared = GitHubService()

    private let token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        // Use provided token or fall back to legacy keychain lookup
        guard let token = token ?? KeychainManager.getToken() else {
            throw GitServiceError.tokenNotConfigured
        }

        var allPRs: [PullRequest] = []
        var cursor: String? = nil
        let pageSize = 100 // Maximum allowed by GitHub GraphQL API

        // Build search query with filters
        var searchQuery = "is:pr is:open review-requested:@me"

        // Add draft filter if requested
        if filterDrafts {
            searchQuery += " -draft:true"
        }

        // Add label exclusions with proper escaping for emojis and special characters
        for label in excludedLabels where !label.isEmpty {
            // Escape quotes in label names and wrap in quotes to handle spaces/emojis
            let escapedLabel = label.replacingOccurrences(of: "\"", with: "\\\"")
            searchQuery += " -label:\"\(escapedLabel)\""
        }

        // Fetch all pages of pull requests
        while true {
            let afterClause = cursor.map { ", after: \"\($0)\"" } ?? ""

            // Escape the search query for GraphQL (escape backslashes and quotes)
            let graphqlEscapedQuery = searchQuery
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")

            let graphqlQuery = """
            {
              search(query: "\(graphqlEscapedQuery)", type: ISSUE, first: \(pageSize)\(afterClause)) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
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

            let (data, response) = try await URLSession.shared.data(for: request)

            // Validate response and check rate limits
            try validateHTTPResponse(response)
            if let rateLimit = extractRateLimitInfo(response) {
                if let remaining = rateLimit.remaining, remaining < 10 {
                    print("GitHub: Low rate limit remaining: \(remaining)")
                }
                // Handle rate limiting with reset date
                if let remaining = rateLimit.remaining, remaining == 0 {
                    throw GitServiceError.rateLimited(resetDate: rateLimit.reset)
                }
            }

            // Parse GraphQL response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = json["data"] as? [String: Any],
                  let search = dataObj["search"] as? [String: Any],
                  let pageInfo = search["pageInfo"] as? [String: Any],
                  let nodes = search["nodes"] as? [[String: Any]] else
            {
                throw GitServiceError.invalidResponse
            }

            let prs = nodes.compactMap { node -> PullRequest? in
                guard let number = node["number"] as? Int,
                      let title = node["title"] as? String,
                      let url = node["url"] as? String,
                      let state = node["state"] as? String,
                      let createdAt = node["createdAt"] as? String,
                      let updatedAt = node["updatedAt"] as? String,
                      let author = node["author"] as? [String: Any],
                      let authorLogin = author["login"] as? String else
                {
                    return nil
                }

                let avatarURL = author["avatarUrl"] as? String ?? ""
                // Use GitHub's stable GraphQL ID
                let id = node["id"] as? String ?? "github-pr-\(number)"
                let isDraft = node["isDraft"] as? Bool ?? false

                // Extract labels
                var labels: [String] = []
                if let labelsData = node["labels"] as? [String: Any],
                   let labelNodes = labelsData["nodes"] as? [[String: Any]]
                {
                    labels = labelNodes.compactMap { $0["name"] as? String }
                }

                return PullRequest(
                    id: id,
                    number: number,
                    title: title,
                    htmlURL: url,
                    state: state.lowercased(),
                    isDraft: isDraft,
                    user: User(login: authorLogin, avatarURL: avatarURL),
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    labels: labels
                )
            }

            allPRs.append(contentsOf: prs)

            // Check if there are more pages
            if let hasNextPage = pageInfo["hasNextPage"] as? Bool,
               hasNextPage,
               let endCursor = pageInfo["endCursor"] as? String
            {
                cursor = endCursor
            } else {
                break
            }
        }

        return allPRs
    }
}
