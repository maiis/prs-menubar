import Foundation

nonisolated struct PullRequest: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let number: Int
    let title: String
    let htmlURL: String
    let state: String
    let isDraft: Bool
    let user: User
    // periphery:ignore We might use it in the future
    let createdAt: String
    let updatedAt: String

    var repositoryName: String {
        guard let url = URL(string: htmlURL),
              let host = url.host else { return "" }

        let pathComponents = url.pathComponents
        guard pathComponents.count >= 3 else { return "" }

        // For GitHub: github.com/owner/repo/pull/123
        // For GitLab: gitlab.com/owner/repo/-/merge_requests/123
        // For Gitea: gitea.example.com/owner/repo/pulls/123
        
        let owner = pathComponents[1]
        let repo = pathComponents[2]
        
        // Remove "/-" prefix for GitLab URLs
        let cleanRepo = repo == "-" && pathComponents.count >= 4 ? pathComponents[3] : repo
        
        return "\(owner)/\(cleanRepo)"
    }

    var updatedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: updatedAt)
    }

    var truncatedTitle: String {
        title.count > 35 ? String(title.prefix(35)) + "…" : title
    }

    enum CodingKeys: String, CodingKey {
        case id, number, title, state, isDraft, user
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
