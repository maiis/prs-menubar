# PRs Menu Bar

[![CI](https://github.com/maiis/prs-menubar/actions/workflows/ci.yml/badge.svg)](https://github.com/maiis/prs-menubar/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple macOS menu bar app that displays pull requests awaiting your review across multiple Git providers.

## Features

- **Multi-Provider Support**: Track pull requests from GitHub, GitLab, and Gitea (self-hosted)
- **Multiple Accounts**: Add and manage multiple accounts from different providers
- Shows PR count directly in the macOS menu bar (checkmark icon when you have 0 PRs, arrow icon with count when you have PRs)
- Click any PR to open it in your browser
- Secure token storage in macOS Keychain
- Auto-refreshes every 5, 10, 15, or 30 minutes
- Manual refresh option with ⌘R
- Built with SwiftUI and Swift 6
- Uses modern async/await patterns
- Requires macOS 15+ (Sequoia or later)

## Supported Providers

- **GitHub**: Public and enterprise GitHub instances
- **GitLab**: GitLab.com and self-hosted GitLab instances
- **Gitea**: Self-hosted Gitea instances

## Installation

### Download Pre-built Release (Recommended)

Download the latest notarized DMG from the [Releases page](https://github.com/maiis/prs-menubar/releases):

1. Download `PRsMenuBar-X.X.X.dmg` from the latest release
2. Open the DMG file
3. Drag "PRs MenuBar.app" to your Applications folder
4. Launch from Applications (the app appears in your menu bar, not the dock)

The app is code-signed and notarized by Apple, so it will run without security warnings.

### Build from Source

If you prefer to build from source:

1. Open the Xcode project:
   ```bash
   open "PRs MenuBar.xcodeproj"
   ```

2. Build and run (⌘R)

The app will appear in your menu bar (not in the dock).

## Setup

### Configure Your Git Provider Accounts

On first launch, the app will show an onboarding screen where you can select your Git provider and configure your account.

#### GitHub

**To create a token:**

1. Go to [GitHub Settings > Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "PRs Menu Bar")
4. Select the `repo` scope
5. Click "Generate token"
6. Copy the token and paste it into the app

#### GitLab

**To create a token:**

1. Go to [GitLab Settings > Access Tokens](https://gitlab.com/-/profile/personal_access_tokens)
2. Create a new token with the `read_api` scope
3. Copy the token and paste it into the app

For self-hosted GitLab instances, you'll also need to provide your GitLab API URL (e.g., `https://gitlab.example.com/api/v4`).

#### Gitea

**To create a token:**

1. Go to your Gitea instance settings > Applications
2. Generate a new token with `read:repository` scope
3. Copy the token and paste it into the app
4. Provide your Gitea API URL (e.g., `https://gitea.example.com/api/v1`)

Your tokens are stored securely in macOS Keychain and never touch the source code.

### Using the App

- The menu bar shows a checkmark icon when you have 0 PRs, an arrow icon with count when you have PRs awaiting review
- Click the menu bar icon to see the list of PRs from all your configured accounts
- Click any PR to open it in your browser
- Use "Refresh Now" or press ⌘R to manually update
- The app auto-refreshes at your configured interval (default: 10 minutes)
- Manage accounts in Settings (⌘,) - add, remove, or disable accounts as needed

## Requirements

- macOS 15.0 (Sequoia) or later
- Swift 6.0
- Xcode 15.0 or later

## Architecture

- **SwiftUI-based**: Modern declarative UI with MenuBarExtra
- **Async/await**: All network calls use structured concurrency
- **@Observable**: State management with Swift's Observation framework
- **Multi-Provider**: Supports GitHub, GitLab, and Gitea with a unified interface
- **Secure Storage**: Tokens stored in macOS Keychain
- **Provider APIs**: 
  - GitHub: GraphQL API for pull requests
  - GitLab: REST API v4 for merge requests
  - Gitea: REST API v1 for pull requests

## File Structure

```
prs-menu-bar/
├── PRs MenuBar/
│   ├── Models/
│   │   ├── PullRequest.swift      # PR data model
│   │   ├── User.swift             # User data model
│   │   ├── GitProvider.swift      # Provider enum (GitHub, GitLab, Gitea)
│   │   └── ProviderAccount.swift  # Account configuration model
│   ├── Views/
│   │   ├── ProviderSelectionView.swift  # Onboarding provider selection
│   │   ├── AddAccountView.swift         # Add/edit account form
│   │   ├── AccountsListView.swift       # Account management in settings
│   │   ├── MenuBarContentView.swift     # Menu content
│   │   ├── SettingsView.swift           # Settings panel
│   │   ├── MenuBarLabelView.swift       # Menu bar icon
│   │   ├── EmptyStateView.swift         # Empty state UI
│   │   ├── PRListItemView.swift         # PR list item
│   │   └── MenuBarStatusView.swift      # Status indicator
│   ├── GitHubService.swift        # GitHub API service
│   ├── GitLabService.swift        # GitLab API service  
│   ├── GiteaService.swift         # Gitea API service
│   ├── GitServiceFactory.swift    # Service factory
│   ├── AppState.swift             # Observable app state
│   ├── AccountManager.swift       # Account configuration manager
│   ├── KeychainManager.swift      # Secure token storage
│   ├── PRsMenuBarApp.swift        # Main app with MenuBarExtra
│   ├── TokenPromptView.swift      # Legacy token entry (deprecated)
│   └── Assets.xcassets            # App assets
├── PRs MenuBar.xcodeproj      # Xcode project
└── README.md
```

## Troubleshooting

**"No accounts configured"**
- Open Settings (⌘,) and add a Git provider account
- Follow the onboarding flow to configure your first account

**"Unauthorized" error**
- Check that your token is valid and has the required scopes
- For GitHub: `repo` scope
- For GitLab: `read_api` scope  
- For Gitea: `read:repository` scope
- Regenerate a new token if needed

**"HTTP error: 403"**
- You may have hit the provider's API rate limit
- GitHub: 5000 requests/hour for authenticated users
- GitLab: 2000 requests/hour for authenticated users
- Wait and it will reset

**PRs not appearing**
- Ensure your account is enabled in Settings
- Check that you're actually requested as a reviewer on the PRs
- Try manually refreshing with ⌘R

**Self-hosted instances (GitLab/Gitea)**
- Verify the API URL is correct (including `/api/v4` for GitLab or `/api/v1` for Gitea)
- Check that your self-hosted instance is accessible from your network
- Ensure SSL certificates are valid if using HTTPS

## Security

Your Git provider tokens are stored securely in macOS Keychain, encrypted by the operating system. They're never stored in source code or configuration files. Each account has its own secure token storage.

For security vulnerability reporting, see [SECURITY.md](SECURITY.md).

## Privacy

See our [Privacy Policy](PRIVACY.md) for details on how the app handles your data.

## Releasing

For maintainers: See [RELEASE.md](RELEASE.md) for detailed instructions on creating GitHub releases with automatic code signing and notarization.

Quick release process:
1. Update version in Xcode project
2. Update CHANGELOG.md
3. Commit and push changes
4. Create and push a version tag: `git tag v1.x.x && git push origin v1.x.x`
5. GitHub Actions will automatically build, notarize, and create a release

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
