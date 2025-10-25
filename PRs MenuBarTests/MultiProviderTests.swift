import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct MultiProviderTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func gitProviderDisplayNames() async throws {
        #expect(GitProvider.github.displayName == "GitHub")
        #expect(GitProvider.gitlab.displayName == "GitLab")
        #expect(GitProvider.gitea.displayName == "Gitea")
    }

    @Test func gitProviderDefaultURLs() async throws {
        #expect(GitProvider.github.defaultBaseURL == "https://api.github.com")
        #expect(GitProvider.gitlab.defaultBaseURL == "https://gitlab.com/api/v4")
        #expect(GitProvider.gitea.defaultBaseURL == "")
    }

    @Test func gitProviderRequiresCustomURL() async throws {
        #expect(GitProvider.github.requiresCustomURL == false)
        #expect(GitProvider.gitlab.requiresCustomURL == false)
        #expect(GitProvider.gitea.requiresCustomURL == true)
    }

    @Test func providerAccountCreation() async throws {
        let account = ProviderAccount(
            provider: .github,
            name: "Test Account",
            baseURL: "https://api.github.com"
        )

        #expect(account.provider == .github)
        #expect(account.name == "Test Account")
        #expect(account.baseURL == "https://api.github.com")
        #expect(account.isEnabled == true)
        #expect(!account.keychainAccount.isEmpty)
    }

    @Test func providerAccountKeychainIdentifier() async throws {
        let account1 = ProviderAccount(provider: .github, name: "Account 1")
        let account2 = ProviderAccount(provider: .github, name: "Account 2")

        // Each account should have a unique keychain identifier
        #expect(account1.keychainAccount != account2.keychainAccount)
    }

    @Test func accountManagerSaveAndRetrieve() async throws {
        let accountManager = AccountManager.shared

        let account = ProviderAccount(
            provider: .github,
            name: "Test Account",
            baseURL: "https://api.github.com"
        )

        accountManager.addAccount(account)

        let accounts = accountManager.getAccounts()
        #expect(accounts.count >= 1)
        #expect(accounts.contains { $0.id == account.id })
    }

    @Test func accountManagerRemoveAccount() async throws {
        let accountManager = AccountManager.shared

        let account = ProviderAccount(
            provider: .gitlab,
            name: "Test GitLab",
            baseURL: "https://gitlab.com/api/v4"
        )

        accountManager.addAccount(account)
        let beforeCount = accountManager.getAccounts().count

        accountManager.removeAccount(account)
        let afterCount = accountManager.getAccounts().count

        #expect(afterCount == beforeCount - 1)
        #expect(!accountManager.getAccounts().contains { $0.id == account.id })
    }

    @Test func pullRequestRepositoryNameGitHub() async throws {
        let pr = PullRequest(
            id: "test-1",
            number: 1,
            title: "Test PR",
            htmlURL: "https://github.com/owner/repo/pull/123",
            state: "open",
            isDraft: false,
            user: User(login: "testuser", avatarURL: ""),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-02T00:00:00Z",
            labels: []
        )

        #expect(pr.repositoryName == "owner/repo")
    }

    @Test func pullRequestRepositoryNameGitLab() async throws {
        let pr = PullRequest(
            id: "test-1",
            number: 1,
            title: "Test MR",
            htmlURL: "https://gitlab.com/owner/repo/-/merge_requests/123",
            state: "opened",
            isDraft: false,
            user: User(login: "testuser", avatarURL: ""),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-02T00:00:00Z",
            labels: []
        )

        #expect(pr.repositoryName == "owner/repo")
    }

    @Test func pullRequestRepositoryNameGitea() async throws {
        let pr = PullRequest(
            id: "test-1",
            number: 1,
            title: "Test PR",
            htmlURL: "https://gitea.example.com/owner/repo/pulls/123",
            state: "open",
            isDraft: false,
            user: User(login: "testuser", avatarURL: ""),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-02T00:00:00Z",
            labels: []
        )

        #expect(pr.repositoryName == "owner/repo")
    }

    @Test func accountManagerMigrationOnlyRunsOnce() async throws {
        let accountManager = AccountManager.shared

        // Clear any existing accounts
        accountManager.saveAccounts([])

        // Reset migration flag
        UserDefaults.standard.removeObject(forKey: "hasMigratedLegacyAccount")

        // First call should attempt migration
        let firstAccounts = accountManager.getAccounts()

        // Second call should not re-migrate
        let secondAccounts = accountManager.getAccounts()

        // Both should return the same result
        #expect(firstAccounts.count == secondAccounts.count)
    }

    @Test func providerAccountStableIDGeneration() async throws {
        // IDs should include baseURL hash for stability across different instances
        let githubAccount = ProviderAccount(
            provider: .github,
            name: "GitHub Account",
            baseURL: "https://api.github.com"
        )

        let gitlabAccount = ProviderAccount(
            provider: .gitlab,
            name: "GitLab Account",
            baseURL: "https://gitlab.com/api/v4"
        )

        // IDs should be different for different providers
        #expect(githubAccount.id != gitlabAccount.id)

        // Creating the same account again should generate a different ID
        let anotherGithubAccount = ProviderAccount(
            provider: .github,
            name: "GitHub Account",
            baseURL: "https://api.github.com"
        )

        #expect(githubAccount.id != anotherGithubAccount.id)
    }

    @Test func gitServiceErrorRateLimitWithResetDate() async throws {
        let resetDate = Date().addingTimeInterval(3600)
        let error = GitServiceError.rateLimited(resetDate: resetDate)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description!.contains("rate limit"))
    }

    @Test func gitServiceErrorInsufficientPermissions() async throws {
        let error = GitServiceError.insufficientPermissions("Missing 'repo' scope")

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description!.contains("Insufficient permissions"))
        #expect(description!.contains("repo"))
    }

    @Test func appStateAccountErrorTracking() async throws {
        let appState = AppState.shared

        // Create test account
        let testAccount = ProviderAccount(
            provider: .github,
            name: "Test Account",
            baseURL: "https://api.github.com"
        )

        // Initially status should be unknown
        let initialStatus = appState.getAccountStatus(testAccount)
        if case .unknown = initialStatus {
            // Expected
        } else {
            Issue.record("Expected unknown status")
        }
    }

    @Test func urlParsingForCustomGiteaInstance() async throws {
        let pr = PullRequest(
            id: "test-1",
            number: 42,
            title: "Custom Gitea PR",
            htmlURL: "https://git.company.com/team/project/pulls/42",
            state: "open",
            isDraft: false,
            user: User(login: "developer", avatarURL: ""),
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-02T00:00:00Z",
            labels: []
        )

        #expect(pr.repositoryName == "team/project")
    }
}
