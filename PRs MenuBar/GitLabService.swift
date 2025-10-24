import Foundation

final class GitLabService: GitHubServiceProtocol, Sendable {
    private let baseURL: String
    private let token: String
    
    init(baseURL: String, token: String) {
        self.baseURL = baseURL
        self.token = token
    }
    
    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        // GitLab uses "merge requests" instead of "pull requests"
        // Get merge requests where the current user is a reviewer
        guard let url = URL(string: "\(baseURL)/merge_requests?scope=all&state=opened&reviewer_username=@me") else {
            throw GitHubError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw GitHubError.unauthorized
            } else if httpResponse.statusCode == 403 {
                throw GitHubError.forbidden
            } else {
                throw GitHubError.httpError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse GitLab merge requests response
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw GitHubError.invalidResponse
        }
        
        let prs = jsonArray.compactMap { mr -> PullRequest? in
            guard let iid = mr["iid"] as? Int,
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
            let id = "gitlab-mr-\(iid)"
            let isDraft = (mr["draft"] as? Bool) ?? false || (title.hasPrefix("Draft:") || title.hasPrefix("WIP:"))
            
            return PullRequest(
                id: id,
                number: iid,
                title: title,
                htmlURL: webURL,
                state: state.lowercased(),
                isDraft: isDraft,
                user: User(login: authorUsername, avatarURL: avatarURL),
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
        
        return prs
    }
}
