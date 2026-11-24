import Foundation

nonisolated struct PullRequest: Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    let htmlURL: String
    let isDraft: Bool
    let user: User
    let updatedAt: String
    var labels: [String]
    /// Maps label name → hex color (without leading "#"), where the provider API exposes it.
    let labelColors: [String: String]
    /// Parsed once here rather than on every render.
    let repositoryName: String

    init(
        id: String,
        number: Int,
        title: String,
        htmlURL: String,
        isDraft: Bool,
        user: User,
        updatedAt: String,
        labels: [String] = [],
        labelColors: [String: String] = [:]
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.htmlURL = htmlURL
        self.isDraft = isDraft
        self.user = user
        self.updatedAt = updatedAt
        self.labels = labels
        self.labelColors = labelColors
        self.repositoryName = Self.parseRepositoryName(from: htmlURL)
    }

    /// GitHub: host/owner/repo/pull/1 · GitLab: host/owner/repo/-/merge_requests/1 · Gitea: host/owner/repo/pulls/1
    private static func parseRepositoryName(from htmlURL: String) -> String {
        guard let url = URL(string: htmlURL), url.host != nil else { return "" }
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 3 else { return "" }
        return "\(pathComponents[1])/\(pathComponents[2])"
    }

    var updatedDate: Date? {
        (try? Date(updatedAt, strategy: Self.iso8601Fractional)) ?? (try? Date(updatedAt, strategy: Self.iso8601))
    }

    /// GitHub and Gitea timestamps use whole seconds, but GitLab's include fractional seconds
    /// ("2017-04-29T08:46:00.054Z") which a whole-seconds parser may reject — try both.
    private static let iso8601Fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let iso8601 = Date.ISO8601FormatStyle()
}
