import SwiftUI

struct PRListItemView: View {

    // MARK: - Properties
    let pr: PullRequest
    let prependRepoName: Bool
    /// True when this row is the keyboard selection, drawn stronger than the hover highlight.
    let isSelected: Bool
    /// Passed down rather than read per row, so toggling a setting doesn't wake an observer
    /// per visible card.
    let showAvatar: Bool
    let showLabels: Bool

    // MARK: - Environment
    @Environment(\.openURL) private var openURL

    // MARK: - State
    @State private var isHovering = false

    // MARK: - UI
    var body: some View {
        Button(action: open) {
            HStack(alignment: .top, spacing: 10) {
                if showAvatar {
                    avatar
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(pr.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if pr.isDraft {
                            Image(systemName: "pencil.and.outline")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .help("Draft")
                        }
                    }

                    metadata
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if showLabels, !pr.labels.isEmpty {
                        labelChips
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            rowBackground,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(pr.title) in \(pr.repositoryName) by \(pr.user.login)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help(pr.title)
    }

    // MARK: - Subviews
    private var avatar: some View {
        AsyncImage(url: pr.user.avatarURL.flatMap(URL.init)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
    }

    private var labelChips: some View {
        HStack(spacing: 4) {
            ForEach(pr.labels.prefix(3), id: \.self) { label in
                chip(label)
            }
            if pr.labels.count > 3 {
                Text("+\(pr.labels.count - 3)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// A label capsule tinted with the provider's color when known, falling back to a neutral fill.
    /// Text color is chosen for contrast against the fill.
    private func chip(_ label: String) -> some View {
        let pair = pr.labelColors[label].flatMap { Color.labelPair(hex: $0) }
        return Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1)
            .foregroundStyle(pair?.text ?? Color.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(pair?.fill ?? Color.secondary.opacity(0.22)))
    }

    // MARK: - Computed Properties
    private var rowBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.22)
        }
        return isHovering ? Color.primary.opacity(0.06) : Color.clear
    }

    /// Single line: "owner/repo #123 · by login · 2h ago" (repo omitted in a group header).
    /// `.relative` gives one unit where `Text(_:style:)` spelled out all of them ("1 hr, 54 min"),
    /// trading a live tick the popover never showed for the shorter string.
    private var metadata: Text {
        let location = prependRepoName ? "\(pr.repositoryName) #\(pr.number)" : "#\(pr.number)"
        guard let updated = pr.updatedDate else {
            return Text("\(location) · by \(pr.user.login)")
        }

        let relative = updated.formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
        return Text("\(location) · by \(pr.user.login) · \(relative)")
    }

    // MARK: - Actions
    private func open() {
        if let url = URL(string: pr.htmlURL) {
            openURL(url)
        }
    }
}

// MARK: - Preview
#Preview("Regular PR") {
    let dateFormatter = ISO8601DateFormatter()
    PRListItemView(
        pr: PullRequest(
            id: "demo-pr-1",
            number: 123,
            title: "Add new authentication flow with OAuth2 support",
            htmlURL: "https://github.com/example/awesome-app/pull/123",
            state: "open",
            isDraft: false,
            user: User(login: "octocat", avatarURL: "https://github.com/octocat.png"),
            createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400 * 2)),
            updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-3600)),
            labels: ["enhancement", "security", "needs-review", "backend"]
        ),
        prependRepoName: true,
        isSelected: false,
        showAvatar: true,
        showLabels: true
    )
    .padding()
    .frame(width: 360)
}

#Preview("Draft PR") {
    let dateFormatter = ISO8601DateFormatter()
    PRListItemView(
        pr: PullRequest(
            id: "demo-pr-2",
            number: 456,
            title: "WIP: Refactor database layer",
            htmlURL: "https://github.com/example/awesome-app/pull/456",
            state: "open",
            isDraft: true,
            user: User(login: "developer1"),
            createdAt: dateFormatter.string(from: Date().addingTimeInterval(-86400)),
            updatedAt: dateFormatter.string(from: Date().addingTimeInterval(-1800)),
            labels: []
        ),
        prependRepoName: false,
        isSelected: true,
        showAvatar: false,
        showLabels: false
    )
    .padding()
    .frame(width: 360)
}
