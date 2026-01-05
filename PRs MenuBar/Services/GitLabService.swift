import Foundation
import OSLog

/// GitLab API service implementation
/// Uses GitLab REST API v4 to fetch merge requests where the current user is a reviewer
/// API Documentation: https://docs.gitlab.com/ee/api/merge_requests.html
final class GitLabService: GitServiceProtocol, Sendable {

    // MARK: - Constants
    private static let perPage = 100

    // MARK: - Properties
    private let baseURL: String
    private let token: String

    // MARK: - Init
    nonisolated init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    // MARK: - Public API
    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        AppLogger.network
            .info("GitLab: Starting MR fetch (filterDrafts: \(filterDrafts), excludedLabels: \(excludedLabels.count))")

        let currentUserId = try await fetchCurrentUserId()
        AppLogger.network.debug("GitLab: Current user ID: \(currentUserId)")

        var urlString = "\(baseURL)/merge_requests?scope=all&state=opened&reviewer_id=\(currentUserId)&per_page=\(Self.perPage)&page=1"

        if filterDrafts {
            urlString += "&wip=no"
        }

        if !excludedLabels.isEmpty {
            var allowedCharacters = CharacterSet.urlQueryAllowed
            allowedCharacters.remove(charactersIn: ",")

            let encodedLabels = excludedLabels
                .filter { !$0.isEmpty }
                .compactMap { $0.addingPercentEncoding(withAllowedCharacters: allowedCharacters) }
                .joined(separator: ",")

            if !encodedLabels.isEmpty {
                urlString += "&not[labels]=\(encodedLabels)"
            }
        }

        guard let url = URL(string: urlString) else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)

        try validateHTTPResponse(response)
        if let rateLimit = extractRateLimitInfo(response) {
            if let remaining = rateLimit.remaining, let limit = rateLimit.limit {
                AppLogger.network.debug("GitLab: Rate limit \(remaining)/\(limit)")
            }
            if let remaining = rateLimit.remaining, remaining < 10 {
                AppLogger.network.warning("GitLab: Low rate limit remaining: \(remaining)")
            }
        }

        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            AppLogger.error.error("GitLab: Invalid response format")
            throw GitServiceError.invalidResponse
        }

        var prs: [PullRequest] = []
        for mr in jsonArray {
            if let pr = parseMergeRequest(mr, baseURL: baseURL) {
                prs.append(pr)
            } else {
                let mrIdentifier = mr["iid"] as? Int ?? mr["id"] as? Int
                AppLogger.network.warning("GitLab: Skipped MR due to missing fields (MR !\(mrIdentifier ?? -1))")
            }
        }

        AppLogger.network.info("GitLab: Fetched \(prs.count) MRs")
        return prs
    }

    // MARK: - Helpers
    /// Fetches the current user's ID from GitLab API
    private func fetchCurrentUserId() async throws -> Int {
        guard let url = URL(string: "\(baseURL)/user") else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request, retryPolicy: .default)

        try validateHTTPResponse(response)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userId = json["id"] as? Int else
        {
            AppLogger.error.error("GitLab: Invalid user response format")
            throw GitServiceError.invalidResponse
        }

        return userId
    }

    /// Parses a GitLab merge request JSON object into a PullRequest model
    private func parseMergeRequest(_ mr: [String: Any], baseURL: String) -> PullRequest? {
        guard let iid = mr["iid"] as? Int,
              let projectId = mr["project_id"] as? Int,
              let title = mr["title"] as? String,
              let webURL = mr["web_url"] as? String,
              let state = mr["state"] as? String,
              let createdAt = mr["created_at"] as? String,
              let updatedAt = mr["updated_at"] as? String,
              let author = mr["author"] as? [String: Any],
              let authorUsername = author["username"] as? String else
        {
            return nil
        }

        let normalizedURL = normalizeURL(baseURL)
        let id = "gitlab-\(normalizedURL)-\(projectId)-\(iid)"

        let isDraft = (mr["draft"] as? Bool) ??
            (mr["work_in_progress"] as? Bool) ??
            title.hasPrefix("Draft:") ||
            title.hasPrefix("WIP:")

        let labels = mr["labels"] as? [String] ?? []

        return PullRequest(
            id: id,
            number: iid,
            title: title,
            htmlURL: webURL,
            state: state.lowercased(),
            isDraft: isDraft,
            user: User(login: authorUsername),
            createdAt: createdAt,
            updatedAt: updatedAt,
            labels: labels
        )
    }
}
