import Foundation

/// Represents the supported Git service providers
enum GitProvider: String, Codable, CaseIterable, Sendable {
    case github = "GitHub"
    case gitlab = "GitLab"
    case gitea = "Gitea"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .github:
            return "chevron.left.forwardslash.chevron.right"
        case .gitlab:
            return "arrow.triangle.branch"
        case .gitea:
            return "cup.and.saucer"
        }
    }
    
    var defaultBaseURL: String {
        switch self {
        case .github:
            return "https://api.github.com"
        case .gitlab:
            return "https://gitlab.com/api/v4"
        case .gitea:
            return "" // Requires custom URL
        }
    }
    
    var tokenSetupURL: String {
        switch self {
        case .github:
            return "https://github.com/settings/tokens"
        case .gitlab:
            return "https://gitlab.com/-/profile/personal_access_tokens"
        case .gitea:
            return "" // Custom instance
        }
    }
    
    var requiresCustomURL: Bool {
        self == .gitea
    }
}
