# PRs Menu Bar

[![CI](https://github.com/maiis/prs-menubar/actions/workflows/ci.yml/badge.svg)](https://github.com/maiis/prs-menubar/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple macOS menu bar app that displays the number of GitHub pull requests awaiting your review.

## Features

- Shows PR count directly in the macOS menu bar (checkmark icon when you have 0 PRs, arrow icon with count when you have PRs)
- Click any PR to open it in your browser
- Secure token storage in macOS Keychain
- Auto-refreshes every 10 minutes
- Manual refresh option with ⌘R
- Built with SwiftUI and Swift 6
- Uses modern async/await patterns
- Requires macOS 15+ (Sequoia or later)

## Setup

### 1. Build and Run

1. Open the Xcode project:
   ```bash
   open "PRs MenuBar.xcodeproj"
   ```

2. Build and run (⌘R)

The app will appear in your menu bar (not in the dock).

### 2. Configure Your GitHub Token

On first launch, the app will prompt you to enter a GitHub Personal Access Token (classic or fine-grained).

**To create a token:**

1. Go to [GitHub Settings > Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Menu Bar App")
4. (Classic) Select the `repo` scope if you need private repos. For public-only, a fine-grained PAT with read-only access to needed repositories is sufficient.
5. Click "Generate token"
6. Copy the token and paste it into the app

Your token is stored securely in macOS Keychain and never touches the source code.

### 3. Using the App

- The menu bar shows a checkmark icon when you have 0 PRs, an arrow icon with count when you have PRs awaiting review
- Click the menu bar icon to see the list of PRs
- Click any PR to open it in your browser
- Use "Refresh Now" or press ⌘R to manually update
- The app auto-refreshes every 10 minutes

## Requirements

- macOS 15.0 (Sequoia) or later
- Swift 6.0
- Xcode 15.0 or later

## Architecture

- **SwiftUI-based**: Modern declarative UI with MenuBarExtra
- **Async/await**: All network calls use structured concurrency
- **@Observable**: State management with Swift's Observation framework
- **GitHub Search API**: Uses `is:pr is:open review-requested:@me` query

## File Structure

```
prs-menu-bar/
├── PRs MenuBar/
│   ├── Models.swift              # Data models for GitHub API responses
│   ├── GitHubService.swift       # API service with async/await
│   ├── AppState.swift            # Observable app state management
│   ├── KeychainManager.swift     # Secure token storage
│   ├── PRsMenuBarApp.swift       # Main SwiftUI app with MenuBarExtra
│   ├── TokenPromptView.swift     # Token entry dialog
│   ├── Info.plist                # App configuration (LSUIElement)
│   └── Assets.xcassets           # App assets
├── PRs MenuBar.xcodeproj      # Xcode project
└── README.md
```

## Troubleshooting

**"GitHub token not found"**
- The app will automatically prompt you to enter a token
- Click "Configure Token" in the error message to re-enter your token

**"Unauthorized"**
- Check that your token is valid and has the `repo` scope
- Regenerate a new token if needed

**"HTTP error: 403"**
- You may have hit GitHub's API rate limit (5000 requests/hour for authenticated users)
- Wait and it will reset

## Security

Your GitHub token is stored securely in macOS Keychain, encrypted by the operating system. It's never stored in source code or configuration files.

For security vulnerability reporting, see [SECURITY.md](SECURITY.md).

## Privacy

See our [Privacy Policy](PRIVACY.md) for details on how the app handles your data.

## Contributing

Pull requests are welcome! Please open an issue first for large changes.

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/thing`
3. Commit changes with clear messages
4. Open a PR describing the motivation

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## Code of Conduct

This project follows the Contributor Covenant. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

## License

MIT - see [LICENSE](LICENSE) for details.
