import SwiftUI

struct PRListItemView: View {
  let pr: PullRequest
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      Text("\(pr.repositoryName) — \(pr.truncatedTitle)")
        .lineLimit(1)
    }
    .help("\(pr.repositoryName) — \(pr.title)")
  }
}
