import Foundation

/// Gitea API service implementation
/// Uses Gitea API v1 to fetch pull requests where the current user is a requested reviewer
/// API Documentation: https://docs.gitea.com/api/1.22/
final class GiteaService: GitHubServiceProtocol, Sendable {
    private let baseURL: String
    private let token: String

    init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    func fetchReviewRequestedPRs(
        filterDrafts: Bool = false,
        excludedLabels: [String] = []
    ) async throws -> [PullRequest] {
        // Use Gitea 1.22.0+ / Forgejo 10.0+ search API
        // Endpoint: /repos/issues/search?type=pulls&review_requested=true
        var allPRs: [PullRequest] = []
        var page = 1
        let perPage = 50

        while true {
            guard let url =
                URL(
                    string: "\(baseURL)/repos/issues/search?type=pulls&review_requested=true&page=\(page)&limit=\(perPage)"
                ) else
            {
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

            if jsonArray.isEmpty {
                break
            }

            let prs = jsonArray.compactMap { issue -> PullRequest? in
                parseIssueAsPullRequest(issue)
            }

            allPRs.append(contentsOf: prs)

            if jsonArray.count < perPage {
                break
            }

            page += 1
        }

        // Apply client-side filtering (API doesn't support it)
        var filtered = allPRs

        if filterDrafts {
            filtered = filtered.filter { !$0.isDraft }
        }

        if !excludedLabels.isEmpty {
            let excludedLabelsLowercase = excludedLabels
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }

            if !excludedLabelsLowercase.isEmpty {
                filtered = filtered.filter { pr in
                    let prLabelsLowercase = pr.labels.map { $0.lowercased() }
                    return !prLabelsLowercase.contains(where: { excludedLabelsLowercase.contains($0) })
                }
            }
        }

        return filtered
    }

    // MARK: - Private Methods

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

        // Extract repository info from URL
        // Format: https://git.company.com/owner/repo/pulls/42
        guard let url = URL(string: htmlURL) else { return nil }
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 4 else { return nil }

        let owner = pathComponents[1]
        let repo = pathComponents[2]

        // Generate stable ID using baseURL hash, owner, repo, and PR number
        let baseURLHash = abs(baseURL.hashValue) % 10000
        let id = "gitea-\(baseURLHash)-\(owner)-\(repo)-\(number)"

        // Gitea 1.17+ supports draft PRs via the 'draft' field
        let isDraft = (issue["draft"] as? Bool) ??
            title.hasPrefix("Draft:") ||
            title.hasPrefix("WIP:") ||
            title.hasPrefix("[WIP]")

        // Extract labels (Gitea returns labels as an array of objects with 'name' field)
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

    /// Fetches the current user's username from Gitea API (unused in new search API)
    private func fetchCurrentUsername() async throws -> String {
        guard let url = URL(string: "\(baseURL)/user") else {
            throw GitServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let username = json["login"] as? String else
        {
            throw GitServiceError.invalidResponse
        }

        return username
    }

    /// Fetches repositories the user has access to
    private func fetchUserRepos(username _: String) async throws -> [[String: Any]] {
        var allRepos: [[String: Any]] = []
        var page = 1
        let perPage = 50

        while true {
            guard let url = URL(string: "\(baseURL)/user/repos?page=\(page)&limit=\(perPage)") else {
                throw GitServiceError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            try validateHTTPResponse(response)

            guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw GitServiceError.invalidResponse
            }

            if jsonArray.isEmpty {
                break
            }

            allRepos.append(contentsOf: jsonArray)

            if jsonArray.count < perPage {
                break
            }

            page += 1
        }

        return allRepos
    }

    /// Fetches pull requests from a specific repository where the user is a requested reviewer
    private func fetchRepoReviewRequestedPRs(
        owner: String,
        repo: String,
        username: String
    ) async throws -> [PullRequest] {
        var allPRs: [PullRequest] = []
        var page = 1
        let perPage = 50

        while true {
            guard let url =
                URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls?state=open&page=\(page)&limit=\(perPage)") else
            {
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

            if jsonArray.isEmpty {
                break
            }

            // Filter PRs where current user is a requested reviewer
            for prData in jsonArray {
                if let requestedReviewers = prData["requested_reviewers"] as? [[String: Any]] {
                    let isReviewer = requestedReviewers.contains { reviewer in
                        (reviewer["login"] as? String) == username
                    }

                    if isReviewer, let pr = parsePullRequest(prData, owner: owner, repo: repo) {
                        allPRs.append(pr)
                    }
                }
            }

            if jsonArray.count < perPage {
                break
            }

            page += 1
        }

        return allPRs
    }

    /// Parses a Gitea pull request JSON object into a PullRequest model
    private func parsePullRequest(_ pr: [String: Any], owner: String, repo: String) -> PullRequest? {
        guard let number = pr["number"] as? Int,
              let title = pr["title"] as? String,
              let htmlURL = pr["html_url"] as? String,
              let state = pr["state"] as? String,
              let createdAt = pr["created_at"] as? String,
              let updatedAt = pr["updated_at"] as? String,
              let user = pr["user"] as? [String: Any],
              let username = user["login"] as? String else
        {
            return nil
        }

        let avatarURL = user["avatar_url"] as? String ?? ""

        // Generate stable ID using baseURL hash, owner, repo, and PR number
        let baseURLHash = abs(baseURL.hashValue) % 10000
        let id = "gitea-\(baseURLHash)-\(owner)-\(repo)-\(number)"

        // Gitea 1.17+ supports draft PRs via the 'draft' field
        let isDraft = (pr["draft"] as? Bool) ??
            title.hasPrefix("Draft:") ||
            title.hasPrefix("WIP:") ||
            title.hasPrefix("[WIP]")

        // Extract labels (Gitea returns labels as an array of objects with 'name' field)
        var labels: [String] = []
        if let labelsArray = pr["labels"] as? [[String: Any]] {
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
