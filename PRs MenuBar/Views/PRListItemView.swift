import SwiftUI

struct PRListItemView: View {

    // MARK: - State
    @AppStorage(UserDefaults.groupByRepoKey) private var groupByRepo = false

    // MARK: - Properties
    let pr: PullRequest
    let onTap: () -> Void

    // MARK: - UI
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .lineLimit(1)
        }
        .help("\(pr.repositoryName) — \(pr.title)")
    }

    // MARK: - Computed Properties
    private var title: String {
        groupByRepo ? pr.truncatedTitle : "\(pr.repositoryName) - \(pr.truncatedTitle)"
    }
}
