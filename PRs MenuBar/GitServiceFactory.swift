import Foundation

/// Factory for creating git service instances based on provider account
enum GitServiceFactory {
    static func createService(for account: ProviderAccount, token: String) -> GitHubServiceProtocol {
        switch account.provider {
        case .github:
            return GitHubService(token: token)
        case .gitlab:
            return GitLabService(baseURL: account.baseURL, token: token)
        case .gitea:
            return GiteaService(baseURL: account.baseURL, token: token)
        }
    }
}
