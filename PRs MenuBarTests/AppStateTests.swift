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
        appState.setAccountError(account.id, error: "Unauthorized")

        #expect(appState.hasAccountErrors == true)
    }

    @Test func hasAccountErrors_disabledAccountWithError_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test", isEnabled: false)
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: "Unauthorized")

        #expect(appState.hasAccountErrors == false)
    }

    @Test func hasAccountErrors_emptyErrorString_returnsFalse() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: "")

        #expect(appState.hasAccountErrors == false)
    }

    // MARK: - aggregatedError Tests

    @Test func aggregatedError_noErrors_returnsNil() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        #expect(appState.aggregatedError == nil)
    }

    @Test func aggregatedError_singleError_returnsErrorMessage() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: "Unauthorized. Please check your access token.")

        #expect(appState.aggregatedError == "Unauthorized. Please check your access token.")
    }

    @Test func aggregatedError_multipleErrors_returnsCount() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account1 = ProviderAccount(provider: .github, name: "GitHub")
        let account2 = ProviderAccount(provider: .gitlab, name: "GitLab")
        appState.setAccounts([account1, account2])
        appState.setAccountError(account1.id, error: "Unauthorized")
        appState.setAccountError(account2.id, error: "Rate limited")

        #expect(appState.aggregatedError == "2 accounts have errors")
    }

    @Test func aggregatedError_disabledAccountsIgnored() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account1 = ProviderAccount(provider: .github, name: "GitHub")
        let account2 = ProviderAccount(provider: .gitlab, name: "GitLab", isEnabled: false)
        appState.setAccounts([account1, account2])
        appState.setAccountError(account1.id, error: "Unauthorized")
        appState.setAccountError(account2.id, error: "Rate limited")

        // Only enabled account's error should be returned
        #expect(appState.aggregatedError == "Unauthorized")
    }

    @Test func aggregatedError_emptyErrorString_ignored() {
        let mockService = MockGitHubService(mockPRs: [])
        let appState = AppState(githubService: mockService)

        let account = ProviderAccount(provider: .github, name: "Test")
        appState.setAccounts([account])
        appState.setAccountError(account.id, error: "")

        #expect(appState.aggregatedError == nil)
    }
}
