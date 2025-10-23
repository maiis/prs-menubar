# Claude Development Notes

## App Name

**App Name:** PRs MenuBar
**Bundle ID:** me.maiis.prsmenubar

The app uses a generic name to avoid trademark issues with "GitHub". It's a menu bar app for viewing GitHub pull requests awaiting review.


### General Guidelines

* Aim to build all functionality using SwiftUI unless there is a feature that is only supported in AppKit.
* Design UI in a way that is idiomatic for the macOS platform and follows Apple Human Interface Guidelines.
* Use SF Symbols for iconography.
* Use the most modern macOS APIs. Since there is no backward compatibility constraint, this app can target the latest macOS versions with the newest APIs.
* Use the most modern Swift language features and conventions. Target Swift 6 and use Swift concurrency (async/await, actors) and Swift macros where applicable.

### Code Style
Do not add excessive comments within function bodies. Only add comments within function bodies to highlight specific details that may not be obvious.
Use 4 spaces for indentation (configured in .swiftformat and .editorconfig)

## Building the Project

When building with xcodebuild, pipe output through xcsift for clean error reporting:

```bash
xcodebuild -project "PRs MenuBar.xcodeproj" -scheme "PRs MenuBar" clean build 2>&1 | xcsift
```

This will give you structured JSON output with just the errors and warnings, filtering out all the verbose Xcode noise.

## Project Structure

- Source files are in `PRs MenuBar/` folder
- Main app entry point: `PRsMenuBarApp.swift`
- Token storage: `KeychainManager.swift` (secure macOS Keychain storage with service ID `me.maiis.prsmenubar`)
- State management: `AppState.swift` (singleton with @Observable, uses @Environment pattern)
- User settings: `UserDefaults.swift` extension for all app preferences
- GitHub API: `GitHubService.swift` (async networking with GitHub GraphQL API)
- Models: Organized in `Models/` folder (PullRequest, User)
- Views: Organized in `Views/` folder (all SwiftUI views)
- Launch at Login: `LaunchAtLoginManager.swift` (using SMAppService)
- No Config.swift - token is prompted on first launch and stored in Keychain

## GitHub API Integration

### Token Requirements
- **Only Classic Personal Access Tokens are supported**
- Fine-grained tokens do NOT work with the GraphQL search queries used by this app
- Required scope: `repo` (Full control of private repositories)
- Create token at: https://github.com/settings/tokens/new

### API Implementation
- Uses **GitHub GraphQL API** for fetching pull requests
- Query: `search(query: "is:pr is:open review-requested:@me", type: ISSUE)`
- GraphQL is more reliable than REST Search API for review requests
- Supports up to 100 PRs per query
- Handles both direct review requests and team-based review requests

## Swift 6 Compliance

This project is **fully Swift 6 compliant** with strict concurrency checking enabled.

### Build Settings
- `SWIFT_VERSION = 6.0`
- `SWIFT_STRICT_CONCURRENCY = complete`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`

### Swift 6 Features Used
- **MenuBarExtra** for native menu bar integration
- **@Observable** for state management with singleton pattern
- **async/await** for all network calls
- **@MainActor** for thread safety (default actor isolation)
- **Sendable** conformance for all data models
- **nonisolated(unsafe)** for data models (PullRequest, User) to allow safe concurrent access
- **Environment** values (@Environment(\.openURL), @Environment(\.openWindow))
- **Native date formatting** with Text(..., style: .relative) for auto-updating timestamps

## Architecture Notes

- **AppState** is a shared singleton accessed via @Environment
  - Marked with `@MainActor` and `@Observable` for safe state updates
  - Refresh timer runs on MainActor with async/await
  - Configurable refresh interval (5, 10, 15, or 30 minutes)
  - Supports sorting (newest/oldest), filtering (hide drafts), and grouping (by repo)
- **State Management Pattern**: Uses `@Environment(AppState.self)` throughout views for consistency
- **Settings Storage**: `@AppStorage` property wrappers for UserDefaults integration
- **Token prompt** appears automatically on first launch if no token in Keychain
- **Launch at Login**: Uses `SMAppService` for macOS 13+ native integration
- **Data models** (PullRequest, User) are `nonisolated(unsafe)`
  - These are immutable value types parsed from GraphQL responses
  - Safe to share across actor boundaries
  - Marked as `Sendable` for strict concurrency checking
  - Use stable GraphQL string IDs (not hash values)
- **GitHubService** uses GraphQL for all API calls
  - Direct JSON parsing instead of Codable for GraphQL responses
  - Manual construction of PullRequest objects from GraphQL data
- **Tests** are comprehensive with 18 tests across 5 suites
  - All tests use `@Suite(.serialized)` with TestHelpers for clean UserDefaults
  - Parallel test execution disabled in scheme to prevent race conditions
