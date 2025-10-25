import Foundation

/// GitLab API service implementation
/// Uses GitLab REST API v4 to fetch merge requests where the current user is a reviewer
/// API Documentation: https://docs.gitlab.com/ee/api/merge_requests.html
final class GitLabService: GitServiceProtocol, Sendable {
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
        // GitLab uses "merge requests" instead of "pull requests"
        // First, get the current user's ID, then fetch MRs where they are a reviewer
        let currentUserId = try await fetchCurrentUserId()

        let perPage = 100 // Maximum items per page

        // Build URL with filters
        var urlString = "\(baseURL)/merge_requests?scope=all&state=opened&reviewer_id=\(currentUserId)&per_page=\(perPage)&page=1"

        // Add draft filter if requested
        if filterDrafts {
            urlString += "&wip=no"
        }

        // Add label exclusions with proper URL encoding for emojis
        if !excludedLabels.isEmpty {
            // Create a character set that excludes comma and other special chars
            var allowedCharacters = CharacterSet.urlQueryAllowed
            allowedCharacters.remove(charactersIn: ",") // Ensure commas are encoded since we use them as separators

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

        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response and check rate limits
        try validateHTTPResponse(response)
        if let rateLimit = extractRateLimitInfo(response) {
            if let remaining = rateLimit.remaining, remaining < 10 {
                print("GitLab: Low rate limit remaining: \(remaining)")
            }
        }

        // Parse GitLab merge requests response
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw GitServiceError.invalidResponse
        }

        return jsonArray.compactMap { mr -> PullRequest? in
            parseMergeRequest(mr, baseURL: baseURL)
        }
    }

    // MARK: - Helpers
    /// Creates a stable, shortened identifier from a URL for use in IDs
    private func normalizeURL(_ url: String) -> String {
        // Remove protocol and trailing slashes
        let normalized = url
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        // Take first 12 chars for brevity while maintaining uniqueness
        return String(normalized.prefix(12))
    }

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

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let userId = json["id"] as? Int else
        {
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

        let avatarURL = author["avatar_url"] as? String ?? ""

        // Generate stable ID using normalized baseURL, project ID, and MR IID
        let normalizedURL = normalizeURL(baseURL)
        let id = "gitlab-\(normalizedURL)-\(projectId)-\(iid)"

        // Check draft status - GitLab has a dedicated field for this
        let isDraft = (mr["draft"] as? Bool) ??
            (mr["work_in_progress"] as? Bool) ??
            title.hasPrefix("Draft:") ||
            title.hasPrefix("WIP:")

        // Extract labels (GitLab returns labels as an array of strings)
        let labels = mr["labels"] as? [String] ?? []

        return PullRequest(
            id: id,
            number: iid,
            title: title,
            htmlURL: webURL,
            state: state.lowercased(),
            isDraft: isDraft,
            user: User(login: authorUsername, avatarURL: avatarURL),
            createdAt: createdAt,
            updatedAt: updatedAt,
            labels: labels
        )
    }
}
