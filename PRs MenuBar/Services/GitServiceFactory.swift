import Foundation

/// Factory for creating git service instances based on provider account
// MARK: - Factory
enum GitServiceFactory {
    nonisolated static func createService(for account: ProviderAccount, token: String) -> GitServiceProtocol {
        switch account.provider {
        case .github:
            GitHubService(token: token)
        case .gitlab:
            GitLabService(baseURL: account.baseURL, token: token)
        case .gitea:
            GiteaService(baseURL: account.baseURL, token: token)
        }
    }
}
