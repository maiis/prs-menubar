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
    private var githubService: GitHubServiceProtocol
    private let accountManager = AccountManager.shared

    // MARK: - Init
    init(githubService: GitHubServiceProtocol? = nil) {
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

    // MARK: - Getters
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
            // In demo mode or when using a test/mock service, use the provided service directly
            // Test services are neither GitHubService, GitLabService, nor GiteaService
            let isTestService = !(githubService is GitHubService) &&
                !(githubService is DemoGitHubService)

            if isDemoMode || isTestService {
                let fetchedPRs = try await githubService.fetchReviewRequestedPRs()
                prs = sortAndFilterPRs(fetchedPRs)
                lastUpdated = Date()
            } else {
                // Fetch PRs from all enabled accounts
                let enabledAccounts = accountManager.getAccounts().filter(\.isEnabled)
                var allPRs: [PullRequest] = []

                for account in enabledAccounts {
                    guard let token = accountManager.getToken(for: account) else {
                        accountErrors[account.id] = "No token found"
                        continue
                    }

                    let service = GitServiceFactory.createService(for: account, token: token)
                    do {
                        let fetchedPRs = try await service.fetchReviewRequestedPRs()
                        allPRs.append(contentsOf: fetchedPRs)

                        // Clear error on success
                        accountErrors[account.id] = nil
                        accountLastFetch[account.id] = Date()
                    } catch {
                        // Store error for this account
                        accountErrors[account.id] = error.localizedDescription
                        print("Error fetching PRs from \(account.displayName): \(error)")
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

    private func sortAndFilterPRs(_ prs: [PullRequest]) -> [PullRequest] {
        var filtered = prs

        // Filter drafts if enabled
        if UserDefaults.standard.filterDrafts {
            filtered = filtered.filter { !$0.isDraft }
        }

        // Filter by excluded labels if configured
        let excludedLabelsString = UserDefaults.standard.excludedLabels
        if !excludedLabelsString.isEmpty {
            let excludedLabels = excludedLabelsString
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }

            if !excludedLabels.isEmpty {
                filtered = filtered.filter { pr in
                    // Exclude PR if it has any of the excluded labels
                    let prLabelsLowercase = pr.labels.map { $0.lowercased() }
                    return !prLabelsLowercase.contains(where: { excludedLabels.contains($0) })
                }
            }
        }

        // Sort by date
        let sorted = filtered.sorted { first, second in
            guard let firstDate = first.updatedDate, let secondDate = second.updatedDate else {
                return false
            }
            return UserDefaults.standard.sortNewestFirst ? firstDate > secondDate : firstDate < secondDate
        }

        return sorted
    }

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
