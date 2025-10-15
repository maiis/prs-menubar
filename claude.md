# Claude Development Notes

## App Name

**App Name:** PRs MenuBar
**Bundle ID:** me.maiis.prsmenubar

The app uses a generic name to avoid trademark issues with "GitHub". It's a menu bar app for viewing GitHub pull requests awaiting review.

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
- State management: `AppState.swift` (singleton with @Observable)
- GitHub API: `GitHubService.swift` (async networking with GitHub API)
- No Config.swift - token is prompted on first launch and stored in Keychain

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
- **nonisolated(unsafe)** for data models (PullRequest, User, GitHubSearchResponse) to allow safe concurrent access
- **Environment** values (@Environment(\.openURL), @Environment(\.openWindow))
- **Native date formatting** with Text(..., style: .relative) for auto-updating timestamps

## Architecture Notes

- **AppState** is a shared singleton accessed via `AppState.shared`
  - Marked with `@MainActor` and `@Observable` for safe state updates
  - Refresh timer runs on MainActor with async/await
- **Token prompt** appears automatically on first launch if no token in Keychain
- **Auto-refresh** runs every 10 minutes (600 seconds) in background Task
- **Data models** (PullRequest, User, GitHubSearchResponse) are `nonisolated(unsafe)`
  - These are immutable value types decoded from JSON
  - Safe to share across actor boundaries
  - Marked as `Sendable` for strict concurrency checking
- **Tests** are minimal - model decoding and basic state tests with Swift 6 compliance
