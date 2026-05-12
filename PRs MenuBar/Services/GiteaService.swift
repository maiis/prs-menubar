import Foundation
import OSLog

/// Gitea API service implementation
/// Uses Gitea API v1 to fetch pull requests where the current user is a requested reviewer
/// API Documentation: https://docs.gitea.com/api/1.22/
final class GiteaService: GitServiceProtocol, Sendable {

    // MARK: - Constants
    private static let perPage = 50

    // MARK: - Properties
    private let baseURL: String
    private let token: String

    // MARK: - Init
    nonisolated init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        AppLogger.network
            .info("Gitea: Starting PR fetch (filterDrafts: \(filterDrafts), excludedLabels: \(excludedLabels.count))")

        guard let url =
            URL(
                string: "\(baseURL)/repos/issues/search?type=pulls&review_requested=true&page=1&limit=\(Self.perPage)"
            ) else
        {
            AppLogger.error.error("Gitea: Invalid URL")
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)

        try validateHTTPResponse(response)
        try checkRateLimit(response, provider: "Gitea")

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let issues: [FailableDecodable<GiteaIssue>]
        do {
            issues = try decoder.decode([FailableDecodable<GiteaIssue>].self, from: data)
        } catch {
            AppLogger.error.error("Gitea: Invalid response format: \(error.localizedDescription)")
            throw GitServiceError.invalidResponse
        }

        let normalizedURL = normalizeURL(baseURL)
        var prs: [PullRequest] = []
        for failable in issues {
            guard let issue = failable.value,
                  let pr = issue.toPullRequest(normalizedURL: normalizedURL) else
            {
                AppLogger.network.warning("Gitea: Skipped PR due to missing fields")
                continue
            }
            prs.append(pr)
        }
        AppLogger.network.debug("Gitea: Parsed \(prs.count) PRs from response")

        let filtered = filterPRs(prs, filterDrafts: filterDrafts, excludedLabels: excludedLabels)

        AppLogger.network.info("Gitea: Fetched \(filtered.count) PRs")
        return filtered
    }
}

// MARK: - Gitea DTOs

private struct GiteaIssue: Decodable {
    let number: Int
    let title: String
    let htmlUrl: String
    let state: String
    let createdAt: String
    let updatedAt: String
    let user: GiteaUser
    let labels: [GiteaLabel]?
    let draft: Bool?

    /// Returns nil if owner/repo can't be parsed from htmlUrl — that's a malformed entry to skip.
    func toPullRequest(normalizedURL: String) -> PullRequest? {
        guard let url = URL(string: htmlUrl) else { return nil }
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 4 else { return nil }

        let owner = pathComponents[1]
        let repo = pathComponents[2]
        let id = "gitea-\(normalizedURL)-\(owner)-\(repo)-\(number)"

        let isDraft = draft
            ?? (title.hasPrefix("Draft:") || title.hasPrefix("WIP:") || title.hasPrefix("[WIP]"))

        return PullRequest(
            id: id,
            number: number,
            title: title,
            htmlURL: htmlUrl,
            state: state.lowercased(),
            isDraft: isDraft,
            user: User(login: user.login),
            createdAt: createdAt,
            updatedAt: updatedAt,
            labels: labels?.map(\.name) ?? []
        )
    }
}

private struct GiteaUser: Decodable {
    let login: String
}

private struct GiteaLabel: Decodable {
    let name: String
}
