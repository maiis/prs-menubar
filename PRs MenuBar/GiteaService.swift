import Foundation

final class GiteaService: GitHubServiceProtocol, Sendable {
    private let baseURL: String
    private let token: String
    
    init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }
    
    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        // Gitea uses similar API to GitHub
        // Get pull requests where the current user is a requested reviewer
        guard let url = URL(string: "\(baseURL)/repos/issues/search?type=pulls&state=open&review_requested=true") else {
            throw GitServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw GitServiceError.unauthorized
            } else if httpResponse.statusCode == 403 {
                throw GitServiceError.forbidden
            } else {
                throw GitServiceError.httpError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse Gitea pull requests response
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw GitServiceError.invalidResponse
        }
        
        let prs = jsonArray.compactMap { pr -> PullRequest? in
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
            let id = "gitea-pr-\(number)"
            
            // Gitea doesn't have a standard isDraft field, check title prefix
            let isDraft = title.hasPrefix("Draft:") || title.hasPrefix("WIP:")
            
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
        
        return prs
    }
}
