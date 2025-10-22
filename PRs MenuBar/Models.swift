import Foundation

// MARK: - GitHub Search Response

nonisolated struct GitHubSearchResponse: Codable, Sendable {
  let totalCount: Int
  let items: [PullRequest]

  enum CodingKeys: String, CodingKey {
    case totalCount = "total_count"
    case items
  }
}

// MARK: - Pull Request

nonisolated struct PullRequest: Codable, Identifiable, Sendable, Equatable {
  let id: Int
  let number: Int
  let title: String
  let htmlURL: String
  let state: String
  let user: User
  let createdAt: String
  let updatedAt: String

  var repositoryName: String {
    guard let url = URL(string: htmlURL),
          let host = url.host,
          host == "github.com" else { return "" }

    let pathComponents = url.pathComponents
    guard pathComponents.count >= 3 else { return "" }

    let owner = pathComponents[1]
    let repo = pathComponents[2]
    return "\(owner)/\(repo)"
  }

  var updatedDate: Date? {
    let formatter = ISO8601DateFormatter()
    return formatter.date(from: updatedAt)
  }

  var truncatedTitle: String {
    title.count > 35 ? String(title.prefix(35)) + "…" : title
  }

  enum CodingKeys: String, CodingKey {
    case id, number, title, state, user
    case htmlURL = "html_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}

// MARK: - User

nonisolated struct User: Codable, Sendable, Equatable {
  let login: String
  let avatarURL: String

  enum CodingKeys: String, CodingKey {
    case login
    case avatarURL = "avatar_url"
  }
}
