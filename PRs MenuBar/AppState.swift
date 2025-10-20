import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    private(set) var prs: [PullRequest] = []
    private(set) var isRefreshing: Bool = false
    private(set) var lastError: String? = nil
    private(set) var lastUpdated: Date? = nil

    var prCount: Int {
        prs.count
    }

    private var refreshTask: Task<Void, Never>?
    private let githubService: GitHubServiceProtocol

    init(githubService: GitHubServiceProtocol = GitHubService.shared) {
        self.githubService = githubService
        startRefreshTimer()
    }

    func refreshPRCount() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        lastError = nil

        do {
            let fetchedPRs = try await githubService.fetchReviewRequestedPRs()
            prs = fetchedPRs
            lastUpdated = Date()
        } catch {
            lastError = error.localizedDescription
        }

        isRefreshing = false
    }

    func cancelRefreshTimer() {
        refreshTask?.cancel()
    }

    private func startRefreshTimer() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            await refreshPRCount()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(600))

                if !Task.isCancelled {
                    await refreshPRCount()
                }
            }
        }
    }

    func manualRefresh() async {
        await refreshPRCount()
    }
}
