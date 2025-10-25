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

    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        // Gitea doesn't have a direct endpoint for "review requested PRs"
        // We need to:
        // 1. Get current user's username
        // 2. Fetch all repos the user has access to
        // 3. For each repo, check for PRs where user is a requested reviewer

        let username = try await fetchCurrentUsername()
        let repos = try await fetchUserRepos(username: username)

        var allPRs: [PullRequest] = []

        // Fetch PRs from each repository
        for repo in repos {
            guard let owner = repo["owner"] as? [String: Any],
                  let ownerLogin = owner["login"] as? String,
                  let repoName = repo["name"] as? String else
            {
                continue
            }

            do {
                let prs = try await fetchRepoReviewRequestedPRs(owner: ownerLogin, repo: repoName, username: username)
                allPRs.append(contentsOf: prs)
            } catch {
                // Continue with other repos if one fails
                print("Gitea: Error fetching PRs from \(ownerLogin)/\(repoName): \(error)")
            }
        }

        return allPRs
    }

    // MARK: - Private Methods

    /// Fetches the current user's username from Gitea API
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

        return PullRequest(
            id: id,
            number: number,
            title: title,
            htmlURL: htmlURL,
            state: state.lowercased(),
            isDraft: isDraft,
            user: User(login: username, avatarURL: avatarURL),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
