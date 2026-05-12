# Claude Development Notes

## App Name

**App Name:** PRs MenuBar
**Bundle ID:** me.maiis.prsmenubar

The app uses a generic name to support multiple Git providers. It's a menu bar app for viewing pull requests awaiting review from GitHub, GitLab, and Gitea.


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

Use the Xcode MCP tools for building and testing. See `~/.claude/CLAUDE.md` for available tools.

## Project Structure

- Source files are in `PRs MenuBar/` folder
- Main app entry point: `PRsMenuBarApp.swift`
- Token storage: `KeychainManager.swift` (secure macOS Keychain storage, per-account)
- Account management: `AccountManager.swift` (@MainActor singleton for thread-safe account operations)
- State management: `AppState.swift` (singleton with @Observable, uses @Environment pattern)
- User settings: `UserDefaults.swift` extension for all app preferences
- Git Services:
  - `GitServiceProtocol.swift` - Protocol for all Git providers
  - `GitHubService.swift` - GitHub GraphQL API
  - `GitLabService.swift` - GitLab REST API v4
  - `GiteaService.swift` - Gitea REST API v1 (1.22.0+/Forgejo 10.0+)
  - `GitServiceFactory.swift` - Factory for creating service instances
  - `GitServiceError.swift` - Unified error handling
- Models: Organized in `Models/` folder (PullRequest, User, GitProvider, ProviderAccount)
- Views: Organized in `Views/` folder (all SwiftUI views, including onboarding and account management)
- Launch at Login: `LaunchAtLoginManager.swift` (using SMAppService)
- Onboarding flow for first-time users to configure accounts

## Git Provider API Integration

### Multi-Provider Support
The app supports three Git providers with a unified `GitServiceProtocol` interface:

#### GitHub
- **API**: GraphQL API v4
- **Token**: Classic Personal Access Token (fine-grained tokens NOT supported for GraphQL search)
- **Required scope**: `repo`
- **Create token**: https://github.com/settings/tokens/new
- **Query**: `search(query: "is:pr is:open review-requested:@me", type: ISSUE, first: 100)`
- **Features**: Handles both direct and team-based review requests, supports label/draft filtering
- **Fetches**: First page only (100 PRs)

#### GitLab
- **API**: REST API v4
- **Token**: Personal Access Token
- **Required scope**: `read_api`
- **Create token**: https://gitlab.com/-/profile/personal_access_tokens
- **Endpoint**: `/merge_requests?scope=all&state=opened&reviewer_id={userId}`
- **Features**: Server-side draft and label filtering
- **Fetches**: First page only (100 MRs)
- **Custom instances**: Supports self-hosted GitLab with custom base URL

#### Gitea/Forgejo
- **API**: REST API v1 (requires 1.22.0+ or Forgejo 10.0+)
- **Token**: Application token
- **Required scopes**: `read:issue`, `read:repository`, and `read:user`
- **Endpoint**: `/repos/issues/search?type=pulls&review_requested=true`
- **Features**: Client-side draft and label filtering (API doesn't support it)
- **Fetches**: First page only (50 PRs)
- **Custom instances**: Always requires custom base URL

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

### State Management
- **AppState** is a shared singleton accessed via @Environment
  - Marked with `@MainActor` and `@Observable` for safe state updates
  - Refresh timer runs on MainActor with async/await
  - Configurable refresh interval (5, 10, 15, or 30 minutes)
  - Supports sorting (newest/oldest), filtering (hide drafts, exclude labels), and grouping (by repo)
  - **Concurrent account fetching**: Uses `withTaskGroup` to fetch from multiple accounts in parallel
  - Tracks per-account errors and last fetch times
- **AccountManager** is a `@MainActor` singleton for thread-safe account operations
  - Manages multiple accounts with unique keychain entries per account
  - Handles account CRUD operations and token storage
  - Automatic migration from legacy single-account setup
- **State Management Pattern**: Uses `@Environment(AppState.self)` throughout views for consistency
- **Settings Storage**: `@AppStorage` property wrappers for UserDefaults integration

### Multi-Provider Architecture
- **GitServiceProtocol**: Unified interface for all Git providers
  - Common HTTP response validation, rate limit checking, and client-side PR filtering via protocol extensions
  - Each service implements `fetchReviewRequestedPRs(filterDrafts:excludedLabels:)`
- **GitServiceFactory**: Creates appropriate service based on provider type
  - Marked as `nonisolated` for use in concurrent contexts
- **Stable ID Generation**: Uses URL normalization instead of hashValue
  - Format: `{provider}-{normalizedURL}-{projectId}-{prNumber}`
  - Ensures consistent IDs across app launches
- **Single Page Fetching**: All services fetch first page only (100/50 PRs)
  - More appropriate for menu bar app
  - Reduces API calls and improves response time

### Data Models
- **Data models** (PullRequest, User) are `nonisolated(unsafe)`
  - Immutable value types safe to share across actor boundaries
  - Marked as `Sendable` for strict concurrency checking
  - Use stable provider-specific IDs (not hash values)
- **Service initializers**: Marked as `nonisolated` for TaskGroup compatibility
- **GitServiceError**: Fully `Sendable` compliant error type

### API Integration
- **GitHubService**: GraphQL API with direct JSON parsing
- **GitLabService**: REST API v4 with server-side filtering
- **GiteaService**: REST API v1 with client-side filtering

### Testing
- **Tests** are comprehensive with 43 tests across 7 suites
  - ServiceTests: GitServiceFactory, HTTP validation (8 tests)
  - MultiProviderTests: Provider infrastructure (16 tests)
  - UserDefaultsTests: Settings persistence (8 tests)
  - SortingFilteringTests: Sorting and filtering logic (4 tests)
  - ModelsTests: Data model behavior (3 tests)
  - AppStateTests: State management (2 tests)
  - GroupingTests: Repository grouping (2 tests)
  - All tests use `@Suite(.serialized)` with TestHelpers for clean UserDefaults
    - Parallel test execution disabled in scheme to prevent race conditions

## MARK Section Conventions

Use structured `// MARK:` headers to organize multi-section types.

Format:
- Always `// MARK: - Section Name` (single space before and after dash)
- No blank line immediately following the MARK line
- Blank line before a MARK unless it is the first content inside a type declaration

When to add:
- Only for files (or nested types) that have multiple distinct logical groups
- Skip simple one-section value types or error enums

Preferred section names (common examples):
- Lifecycle / Structure: `Singleton`, `Init`, `Deinit`
- Data & Members: `Properties`, `State`, `Environment`, `Computed Properties`, `Constants`
- Behavior: `Actions`, `Helpers`, `Public API`, `Private API`, `Refresh Timer`
- UI: `UI`, `Preview`
- Factories / Patterns: `Factory`, `Protocol Conformance` (use specific protocol name when helpful)

Discouraged / avoid:
- `Body` (use `UI`)
- `Getters` (use `Computed Properties`)
- Generic buckets like `Misc`, `Other`, `Data`

Ordering guideline (adapt pragmatically):
1. `Singleton` (if applicable)
2. `Properties` / `State` / `Environment`
3. `Init`
4. `Computed Properties`
5. `Actions` / `Public API`
6. `Helpers`
7. Specialized sections (e.g. `Refresh Timer`)
8. `UI`
9. `Preview`

Nested private helper views:
- Only add MARKs if they themselves contain multiple grouped sections; otherwise omit to reduce noise.

Consistency rules:
- Use the same casing and spacing project‑wide
- Do not duplicate consecutive identical MARKs
- Keep section scope meaningful: do not create a section for a single trivial one-liner unless it improves scanability.

