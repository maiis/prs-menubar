import Foundation
import OSLog

/// GitHub API service implementation
/// Uses GitHub GraphQL API v4 to fetch pull requests where the current user is a requested reviewer
/// API Documentation: https://docs.github.com/en/graphql
final class GitHubService: GitServiceProtocol, Sendable {
    static let shared = GitHubService()

    // MARK: - Constants
    private static let pageSize = 100

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
          search(query: "\(graphqlEscapedQuery)", type: ISSUE, first: \(Self.pageSize)) {
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

        let body = GraphQLRequest(query: graphqlQuery)
        let jsonData = try JSONEncoder().encode(body)

        guard let url = URL(string: "https://api.github.com/graphql") else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let decoded: GraphQLResponse = try await performJSON(request, provider: "GitHub")

        if let firstError = decoded.errors?.first {
            AppLogger.error.error("GitHub: GraphQL error - \(firstError.message)")
            throw GitServiceError.networkError(firstError.message)
        }

        guard let nodes = decoded.data?.search.nodes else {
            AppLogger.error.error("GitHub: Invalid response format")
            throw GitServiceError.invalidResponse
        }

        var prs: [PullRequest] = []
        for failable in nodes {
            guard let node = failable.value else {
                AppLogger.network.warning("GitHub: Skipped PR due to missing fields")
                continue
            }
            prs.append(PullRequest(
                id: node.id,
                number: node.number,
                title: node.title,
                htmlURL: node.url,
                state: node.state.lowercased(),
                isDraft: node.isDraft ?? false,
                user: User(login: node.author.login),
                createdAt: node.createdAt,
                updatedAt: node.updatedAt,
                labels: node.labels?.nodes.map(\.name) ?? []
            ))
        }

        AppLogger.network.info("GitHub: Fetched \(prs.count) PRs")
        return prs
    }
}

// MARK: - GraphQL DTOs

private struct GraphQLRequest: Encodable {
    let query: String
}

private struct GraphQLResponse: Decodable {
    let data: GraphQLData?
    let errors: [GraphQLError]?
}

private struct GraphQLError: Decodable {
    let message: String
}

private struct GraphQLData: Decodable {
    let search: GitHubSearchResult
}

private struct GitHubSearchResult: Decodable {
    let nodes: [FailableDecodable<GitHubPRNode>]
}

private struct GitHubPRNode: Decodable {
    let id: String
    let number: Int
    let title: String
    let url: String
    let state: String
    let isDraft: Bool?
    let createdAt: String
    let updatedAt: String
    let author: GitHubAuthor
    let labels: GitHubLabels?
}

private struct GitHubAuthor: Decodable {
    let login: String
}

private struct GitHubLabels: Decodable {
    let nodes: [GitHubLabel]
}

private struct GitHubLabel: Decodable {
    let name: String
}
