import Foundation

protocol GitHubServiceProtocol: Sendable {
    func fetchReviewRequestedPRs() async throws -> [PullRequest]
}

final class GitHubService: GitHubServiceProtocol, Sendable {
    static let shared = GitHubService()

    init() {}

    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        guard let token = KeychainManager.getToken() else {
            throw GitHubError.tokenNotConfigured
        }

        let graphqlQuery = """
        {
          search(query: "is:pr is:open review-requested:@me", type: ISSUE, first: 100) {
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
              }
            }
          }
        }
        """

        let graphqlBody: [String: Any] = ["query": graphqlQuery]
        let jsonData = try JSONSerialization.data(withJSONObject: graphqlBody)

        guard let url = URL(string: "https://api.github.com/graphql") else {
            throw GitHubError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw GitHubError.unauthorized
            } else if httpResponse.statusCode == 403 {
                if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
                   remaining == "0"
                {
                    throw GitHubError.rateLimited
                }
                throw GitHubError.forbidden
            } else {
                throw GitHubError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        // Parse GraphQL response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let search = dataObj["search"] as? [String: Any],
              let nodes = search["nodes"] as? [[String: Any]] else
        {
            throw GitHubError.invalidResponse
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
            let id = node["id"] as? String ?? "pr-\(number)"
            let isDraft = node["isDraft"] as? Bool ?? false

            return PullRequest(
                id: id,
                number: number,
                title: title,
                htmlURL: url,
                state: state.lowercased(),
                isDraft: isDraft,
                user: User(login: authorLogin, avatarURL: avatarURL),
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }

        return prs
    }
}
