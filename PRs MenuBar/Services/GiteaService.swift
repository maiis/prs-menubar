import Foundation

/// Gitea API service implementation
/// Uses Gitea API v1 to fetch pull requests where the current user is a requested reviewer
/// API Documentation: https://docs.gitea.com/api/1.22/
final class GiteaService: GitServiceProtocol, Sendable {
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
        let perPage = 50

        guard let url =
            URL(string: "\(baseURL)/repos/issues/search?type=pulls&review_requested=true&page=1&limit=\(perPage)") else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)
        if let rateLimit = extractRateLimitInfo(response) {
            if let remaining = rateLimit.remaining, remaining < 10 {
                print("Gitea: Low rate limit remaining: \(remaining)")
            }
        }

        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw GitServiceError.invalidResponse
        }

        let prs = jsonArray.compactMap { issue -> PullRequest? in
            parseIssueAsPullRequest(issue)
        }

        // Apply client-side filtering (API doesn't support it)
        var filtered = prs

        if filterDrafts {
            filtered = filtered.filter { !$0.isDraft }
        }

        if !excludedLabels.isEmpty {
            let excludedLabelsSet = Set(
                excludedLabels
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                    .filter { !$0.isEmpty }
            )

            if !excludedLabelsSet.isEmpty {
                filtered = filtered.filter { pr in
                    !pr.labels.contains(where: { excludedLabelsSet.contains($0.lowercased()) })
                }
            }
        }

        return filtered
    }

    // MARK: - Helpers
    /// Creates a stable, shortened identifier from a URL for use in IDs
    private func normalizeURL(_ url: String) -> String {
        let normalized = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        return String(normalized.prefix(12))
    }

    /// Parses a Gitea issue (from search API) into a PullRequest model
    private func parseIssueAsPullRequest(_ issue: [String: Any]) -> PullRequest? {
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

        let avatarURL = user["avatar_url"] as? String ?? ""

        guard let url = URL(string: htmlURL) else { return nil }
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 4 else { return nil }

        let owner = pathComponents[1]
        let repo = pathComponents[2]

        let normalizedURL = normalizeURL(baseURL)
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
            user: User(login: username, avatarURL: avatarURL),
            createdAt: createdAt,
            updatedAt: updatedAt,
            labels: labels
        )
    }
}
