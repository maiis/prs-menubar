# Changelog

All notable changes to PRs MenuBar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of PRs MenuBar
- Menu bar integration showing PR count
- GitHub Personal Access Token authentication
- Secure token storage in macOS Keychain
- Auto-refresh every 10 minutes
- Manual refresh with ⌘R keyboard shortcut
- Click-to-open PRs in browser
- Real-time status updates
- Error handling with user-friendly messages
- Swift 6 compliance with strict concurrency
- Modern async/await architecture
- App sandbox with minimal permissions

### Technical Details
- Built with SwiftUI and Swift 6
- MenuBarExtra for native menu bar integration
- @Observable macro for state management
- GitHub Search API integration
- Requires macOS 15.0 (Sequoia) or later

## [1.0.0] - TBD

Initial public release.

### Features
- View GitHub pull requests awaiting your review
- Menu bar icon shows PR count
- Secure token management
- Auto-refresh functionality
- One-click PR access

---

## Release Notes Template

For future releases, use this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```
