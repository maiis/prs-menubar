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

    private var refreshTask: Task<Void, Never>?
    private var githubService: GitHubServiceProtocol

    // MARK: - Init
    init(githubService: GitHubServiceProtocol? = nil) {
        let isDemo = UserDefaults.standard.isDemoMode
        self.isDemoMode = isDemo
        self.githubService = githubService ?? (isDemo ? DemoGitHubService.shared : GitHubService.shared)
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
            let fetchedPRs = try await githubService.fetchReviewRequestedPRs()
            prs = sortAndFilterPRs(fetchedPRs)
            lastUpdated = Date()
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

    private func sortAndFilterPRs(_ prs: [PullRequest]) -> [PullRequest] {
        var filtered = prs

        // Filter drafts if enabled
        if UserDefaults.standard.filterDrafts {
            filtered = filtered.filter { !$0.isDraft }
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
