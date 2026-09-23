nonisolated struct User: Codable, Equatable {
    let login: String
    let avatarURL: String?

    init(login: String, avatarURL: String? = nil) {
        self.login = login
        self.avatarURL = avatarURL
    }
}
