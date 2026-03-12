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
            URL(string: "\(baseURL)/repos/issues/search?type=pulls&review_requested=true&page=1&limit=\(Self.perPage)") else {
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

        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            AppLogger.error.error("Gitea: Invalid response format")
            throw GitServiceError.invalidResponse
        }

        let normalizedURL = normalizeURL(baseURL)
        var prs: [PullRequest] = []
        for issue in jsonArray {
            if let pr = parseIssueAsPullRequest(issue, normalizedURL: normalizedURL) {
                prs.append(pr)
            } else {
                let prIdentifier = issue["number"] as? Int ?? issue["id"] as? Int
                AppLogger.network.warning("Gitea: Skipped PR due to missing fields (PR #\(prIdentifier ?? -1))")
            }
        }
        AppLogger.network.debug("Gitea: Parsed \(prs.count) PRs from response")

        let filtered = filterPRs(prs, filterDrafts: filterDrafts, excludedLabels: excludedLabels)

        AppLogger.network.info("Gitea: Fetched \(filtered.count) PRs")
        return filtered
    }

    // MARK: - Helpers
    /// Parses a Gitea issue (from search API) into a PullRequest model
    private func parseIssueAsPullRequest(_ issue: [String: Any], normalizedURL: String) -> PullRequest? {
        guard let number = issue["number"] as? Int,
              let title = issue["title"] as? String,
              let htmlURL = issue["html_url"] as? String,
              let state = issue["state"] as? String,
              let createdAt = issue["created_at"] as? String,
              let updatedAt = issue["updated_at"] as? String,
              let user = issue["user"] as? [String: Any],
              let username = user["login"] as? String else
        {
            return nil
        }

        guard let url = URL(string: htmlURL) else { return nil }
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 4 else { return nil }

        let owner = pathComponents[1]
        let repo = pathComponents[2]

        let id = "gitea-\(normalizedURL)-\(owner)-\(repo)-\(number)"

        let isDraft = (issue["draft"] as? Bool) ??
            title.hasPrefix("Draft:") ||
            title.hasPrefix("WIP:") ||
            title.hasPrefix("[WIP]")

        var labels: [String] = []
        if let labelsArray = issue["labels"] as? [[String: Any]] {
            labels = labelsArray.compactMap { $0["name"] as? String }
        }

        return PullRequest(
            id: id,
            number: number,
            title: title,
            htmlURL: htmlURL,
            state: state.lowercased(),
            isDraft: isDraft,
            user: User(login: username),
            createdAt: createdAt,
            updatedAt: updatedAt,
            labels: labels
        )
    }
}
