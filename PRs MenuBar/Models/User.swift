nonisolated struct User: Codable, Sendable, Equatable {
    let login: String
    // periphery:ignore We might use it in the future
    let avatarURL: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}
