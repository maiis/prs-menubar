import Foundation

// Shared date formatter to avoid repeated instantiation
private let sharedISO8601Formatter: ISO8601DateFormatter = {
    ISO8601DateFormatter()
}()

nonisolated struct PullRequest: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let number: Int
    let title: String
    let htmlURL: String
    let state: String
    let isDraft: Bool
    let user: User
    let createdAt: String
    let updatedAt: String
    var labels: [String]
    
    // Cached repository name to avoid repeated URL parsing
    private let _repositoryName: String

    // Standard initializer for creating instances
    init(
        id: String,
        number: Int,
        title: String,
        htmlURL: String,
        state: String,
        isDraft: Bool,
        user: User,
        createdAt: String,
        updatedAt: String,
        labels: [String] = []
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.htmlURL = htmlURL
        self.state = state
        self.isDraft = isDraft
        self.user = user
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.labels = labels
        
        // Compute and cache repository name at initialization
        self._repositoryName = Self.parseRepositoryName(from: htmlURL)
    }

    var repositoryName: String {
        _repositoryName
    }
    
    // Static helper to parse repository name from URL
    private static func parseRepositoryName(from htmlURL: String) -> String {
        guard let url = URL(string: htmlURL),
              url.host != nil else { return "" }

        let pathComponents = url.pathComponents

        // For GitHub: github.com/owner/repo/pull/123
        // For GitLab: gitlab.com/owner/repo/-/merge_requests/123
        // For Gitea: gitea.example.com/owner/repo/pulls/123

        // GitLab has "/-/" in the path before "merge_requests"
        if pathComponents.contains("-") {
            // Find the position of "/-/" and get owner/repo before it
            if let dashIndex = pathComponents.firstIndex(of: "-"), dashIndex >= 3 {
                let owner = pathComponents[1]
                let repo = pathComponents[2]
                return "\(owner)/\(repo)"
            }
        }

        // Standard GitHub/Gitea format
        guard pathComponents.count >= 3 else { return "" }
        let owner = pathComponents[1]
        let repo = pathComponents[2]

        return "\(owner)/\(repo)"
    }

    var updatedDate: Date? {
        sharedISO8601Formatter.date(from: updatedAt)
    }

    var truncatedTitle: String {
        title.count > 35 ? String(title.prefix(35)) + "…" : title
    }

    enum CodingKeys: String, CodingKey {
        case id, number, title, state, isDraft, user, labels
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to initialize cached repository name
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        htmlURL = try container.decode(String.self, forKey: .htmlURL)
        state = try container.decode(String.self, forKey: .state)
        isDraft = try container.decode(Bool.self, forKey: .isDraft)
        user = try container.decode(User.self, forKey: .user)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        labels = try container.decode([String].self, forKey: .labels)
        
        // Compute and cache repository name
        _repositoryName = Self.parseRepositoryName(from: htmlURL)
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(number, forKey: .number)
        try container.encode(title, forKey: .title)
        try container.encode(htmlURL, forKey: .htmlURL)
        try container.encode(state, forKey: .state)
        try container.encode(isDraft, forKey: .isDraft)
        try container.encode(user, forKey: .user)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(labels, forKey: .labels)
    }
}
