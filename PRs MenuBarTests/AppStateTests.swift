import Foundation
import Testing
@testable import PRs_MenuBar

@Suite(.serialized)
@MainActor
struct AppStateTests {

    init() {
        TestHelpers.cleanupUserDefaults()
    }

    @Test func initialState() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.prs.isEmpty)
        #expect(appState.prCount == 0)
        #expect(!appState.isRefreshing)
        #expect(appState.lastError == nil)
    }

    @Test func prCountComputedProperty() async {
        let mockPRs = [
            PullRequest(
                id: "test-pr-1",
                number: 100,
                title: "Test PR 1",
                htmlURL: "https://github.com/test/repo/pull/100",
                state: "open",
                isDraft: false,
                user: User(login: "testuser"),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z",
                labels: []
            ),
            PullRequest(
                id: "test-pr-2",
                number: 200,
                title: "Test PR 2",
                htmlURL: "https://github.com/test/repo/pull/200",
                state: "open",
                isDraft: false,
                user: User(login: "testuser2"),
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z",
                labels: []
            )
        ]

        let mockService = MockGitHubService(mockPRs: mockPRs)
        let appState = AppState(githubService: mockService)

        await appState.refreshPRCount()

        #expect(appState.prCount == 2)
        #expect(appState.prs.count == 2)
    }

    // MARK: - hasAccountErrors Tests

    @Test func hasAccountErrors_noErrors_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.hasAccountErrors == false)
    }

    @Test func hasAccountErrors_enabledAccountWithError_returnsTrue() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: .unauthorized)

        #expect(appState.hasAccountErrors == true)
    }

    @Test func hasAccountErrors_disabledAccountWithError_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test", isEnabled: false)
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: .unauthorized)

        #expect(appState.hasAccountErrors == false)
    }

    @Test func hasAccountErrors_nilError_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: nil)

        #expect(appState.hasAccountErrors == false)
    }

    // MARK: - displayError Tests

    @Test func displayError_noErrors_returnsNil() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.displayError == nil)
    }

    @Test func displayError_singleError_returnsTypedError() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: .unauthorized)

        #expect(appState.displayError?.error == .unauthorized)
        #expect(appState.displayError?.additionalAccountsAffected == 0)
    }

    @Test func displayError_multipleErrors_reportsAdditionalCount() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account1 = ProviderAccount(provider: .github, name: "GitHub")
        let account2 = ProviderAccount(provider: .gitlab, name: "GitLab")
        appState.setAccounts([account1, account2])
        appState.setAccountError(account1.id, error: .unauthorized)
        appState.setAccountError(account2.id, error: .rateLimited(resetDate: nil))

        // Sorted by errorDescription, so "API rate limit..." comes before "Unauthorized..."
        #expect(appState.displayError?.error == .rateLimited(resetDate: nil))
        #expect(appState.displayError?.additionalAccountsAffected == 1)
    }

    @Test func displayError_disabledAccountsIgnored() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account1 = ProviderAccount(provider: .github, name: "GitHub")
        let account2 = ProviderAccount(provider: .gitlab, name: "GitLab", isEnabled: false)
        appState.setAccounts([account1, account2])
        appState.setAccountError(account1.id, error: .unauthorized)
        appState.setAccountError(account2.id, error: .rateLimited(resetDate: nil))

        #expect(appState.displayError?.error == .unauthorized)
        #expect(appState.displayError?.additionalAccountsAffected == 0)
    }

    @Test func displayError_nilError_ignored() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: nil)

        #expect(appState.displayError == nil)
    }
}
