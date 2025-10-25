import Foundation

/// Represents the supported Git service providers
enum GitProvider: String, Codable, CaseIterable, Sendable, Identifiable {
    var id: String { rawValue }
    case github = "GitHub"
    case gitlab = "GitLab"
    case gitea = "Gitea"

    var displayName: String {
        rawValue
    }

    var iconName: String {
        switch self {
        case .github:
            "chevron.left.forwardslash.chevron.right"
        case .gitlab:
            "arrow.triangle.branch"
        case .gitea:
            "cup.and.saucer"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .github:
            "https://api.github.com"
        case .gitlab:
            "https://gitlab.com/api/v4"
        case .gitea:
            "" // Requires custom URL
        }
    }

    var tokenSetupURL: String {
        switch self {
        case .github:
            "https://github.com/settings/tokens"
        case .gitlab:
            "https://gitlab.com/-/user_settings/personal_access_tokens"
        case .gitea:
            "" // Custom instance
        }
    }

    var requiresCustomURL: Bool {
        self == .gitea
    }
}
