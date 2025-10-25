import Foundation
import Observation

@MainActor
@Observable
final class AppState {

    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - Properties
    private(set) var prs: [PullRequest] = []
    private(set) var isRefreshing = false
    private(set) var lastError: String?
    private(set) var lastUpdated: Date?
    private(set) var isDemoMode = false
    private(set) var accounts: [ProviderAccount] = []
    private(set) var accountErrors: [UUID: String] = [:]
    private(set) var accountLastFetch: [UUID: Date] = [:]

    private var refreshTask: Task<Void, Never>?
    private var githubService: GitServiceProtocol
    private let accountManager = AccountManager.shared

    // MARK: - Init
    init(githubService: GitServiceProtocol? = nil) {
        let isDemo = UserDefaults.standard.isDemoMode
        self.isDemoMode = isDemo
        // If a githubService is provided (for testing), use it; otherwise use demo or real service
        if let provided = githubService {
            self.githubService = provided
        } else {
            self.githubService = isDemo ? DemoGitHubService.shared : GitHubService.shared
        }
        self.accounts = accountManager.getAccounts()
        startRefreshTimer()
    }

    // MARK: - Computed Properties
    var prCount: Int {
        prs.count
    }

    var groupedPRs: [(String, [PullRequest])] {
        guard UserDefaults.standard.groupByRepo else {
            return [("", prs)]
        }

        let grouped = Dictionary(grouping: prs) { $0.repositoryName }
        return grouped.sorted { $0.key < $1.key }
    }

    // MARK: - Actions
    func setDemoMode(_ enabled: Bool) {
        isDemoMode = enabled
        UserDefaults.standard.isDemoMode = enabled
        githubService = enabled ? DemoGitHubService.shared : GitHubService.shared
        Task {
            await refreshPRCount()
        }
    }

    func refreshPRCount() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        lastError = nil

        do {
            // Get filter settings
            let filterDrafts = UserDefaults.standard.filterDrafts
            let excludedLabelsString = UserDefaults.standard.excludedLabels
            let excludedLabels = excludedLabelsString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            // In demo mode or when using a test/mock service, use the provided service directly
            // Test services are neither GitHubService, GitLabService, nor GiteaService
            let isTestService = !(githubService is GitHubService) &&
                !(githubService is DemoGitHubService)

            if isDemoMode || isTestService {
                let fetchedPRs = try await githubService.fetchReviewRequestedPRs(
                    filterDrafts: filterDrafts,
                    excludedLabels: excludedLabels
                )
                prs = sortAndFilterPRs(fetchedPRs)
                lastUpdated = Date()
            } else {
                // Fetch PRs from all enabled accounts concurrently
                let enabledAccounts = accountManager.getAccounts().filter(\.isEnabled)
                var allPRs: [PullRequest] = []

                await withTaskGroup(of: (UUID, Result<[PullRequest], Error>).self) { group in
                    for account in enabledAccounts {
                        guard let token = accountManager.getToken(for: account) else {
                            accountErrors[account.id] = "No token found"
                            continue
                        }

                        group.addTask {
                            let service = GitServiceFactory.createService(for: account, token: token)
                            let result: Result<[PullRequest], Error>
                            do {
                                let prs = try await service.fetchReviewRequestedPRs(
                                    filterDrafts: filterDrafts,
                                    excludedLabels: excludedLabels
                                )
                                result = .success(prs)
                            } catch {
                                result = .failure(error)
                            }
                            return (account.id, result)
                        }
                    }

                    for await (accountId, result) in group {
                        switch result {
                        case let .success(fetchedPRs):
                            allPRs.append(contentsOf: fetchedPRs)
                            accountErrors[accountId] = nil
                            accountLastFetch[accountId] = Date()
                        case let .failure(error):
                            accountErrors[accountId] = error.localizedDescription
                            if let account = enabledAccounts.first(where: { $0.id == accountId }) {
                                print("Error fetching PRs from \(account.displayName): \(error)")
                            }
                        }
                    }
                }

                prs = sortAndFilterPRs(allPRs)
                lastUpdated = Date()
            }
        } catch {
            lastError = error.localizedDescription
        }

        isRefreshing = false
    }

    func manualRefresh() async {
        await refreshPRCount()
    }

    func restartRefreshTimer() {
        startRefreshTimer()
    }

    func reloadAccounts() {
        accounts = accountManager.getAccounts()
    }

    func getAccountStatus(_ account: ProviderAccount) -> AccountStatus {
        if let error = accountErrors[account.id] {
            .error(error)
        } else if let lastFetch = accountLastFetch[account.id] {
            .success(lastFetch)
        } else if isRefreshing {
            .loading
        } else {
            .unknown
        }
    }

    enum AccountStatus {
        case loading
        case success(Date)
        case error(String)
        case unknown
    }

    // MARK: - Helpers
    private func sortAndFilterPRs(_ prs: [PullRequest]) -> [PullRequest] {
        // Note: Draft and label filtering is now done at the API level for GitHub/GitLab
        // Gitea performs filtering on the client side within its service implementation
        // This function now only handles sorting

        // Sort by date
        let sorted = prs.sorted { first, second in
            guard let firstDate = first.updatedDate, let secondDate = second.updatedDate else {
                return false
            }
            return UserDefaults.standard.sortNewestFirst ? firstDate > secondDate : firstDate < secondDate
        }

        return sorted
    }

    // MARK: - Refresh Timer
    private func startRefreshTimer() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            await refreshPRCount()

            while !Task.isCancelled {
                let interval = UserDefaults.standard.refreshInterval
                try? await Task.sleep(for: .seconds(interval))

                if !Task.isCancelled {
                    await refreshPRCount()
                }
            }
        }
    }
}
