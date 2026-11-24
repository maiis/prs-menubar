# Changelog

All notable changes to PRs MenuBar will be documented in this file.

## [2.0] - Unreleased

### Added
- Redesigned menu bar panel: pull requests are now cards in a scrollable list, with author avatars, colored label chips, and live relative timestamps
- Swipe a card to open it or copy its URL (macOS 27); the same actions are on right-click everywhere
- Keyboard navigation in the panel: arrow keys move the selection (wrapping at both ends) and Return opens the selected pull request
- Accounts can be dragged into any order in Settings, and the order is persisted (macOS 27)
- "Show Author Avatars" and "Show Labels" toggles in Display settings; hiding avatars also stops fetching their images, and hiding labels affects the card only, not the Exclude Labels filter
- Author avatars are cached on disk in a dedicated, size-bounded URL session (macOS 27)
- Polling backs off to a 30-minute floor and stops issuing transient retries while macOS reports that it prefers reduced resource usage (macOS 27)

### Changed
- **Minimum macOS is now 15.0 (Sequoia)**, up from 14.6
- The menu bar panel is a window-style popover rather than a menu
- Text fields adopt macOS 27's `.bordered` style with an explicit border shape, replacing the deprecated `.roundedBorder`

### Fixed
- One unreachable account no longer holds the whole panel on its loading spinner: request timeouts fail fast instead of stacking three full-length retries (worst case ~90s → ~15s)

## [1.12] - 2026-06-15

### Fixed
- "Paste Token" button now works when adding an account
- Filter toggles (hide drafts, exclude labels) now persist reliably
- Draft pull requests are correctly hidden across all providers, including Gitea
- Corrupted account data now recovers gracefully instead of returning empty

### Improved
- Clearer error messages for rate limits, expired tokens, and missing token scopes
- Improved accessibility labels and VoiceOver support throughout
- Friendlier refresh affordance with better rate-limit handling

### Security
- Keychain tokens are now pinned to this device (first-unlock accessibility)

## [1.10] - 2026-03-10

### Improved
- Enriched PR menu items: hover to reveal submenu with author, repository, timestamps, labels, and draft status
- Added "Copy URL" action in PR submenu
- Draft PRs now display a pencil icon for quick visual identification
- Improved accessibility labels with author information

### Changed
- Click on a PR still opens in browser; hover now reveals details submenu
- Moved URL handling into individual PR items for better encapsulation

## [1.9] - 2026-03-03

### Improved
- Improved reliability and responsiveness of menu bar updates during refresh

## [1.8] - 2026-02-11

### Fixed
- Fixed critical infinite recursion crash caused by multiple `@Observable` dictionary mutations during refresh operations
- Batched account error updates into single assignments to prevent cascading SwiftUI update cycles

## [1.7] - 2026-02-11

### Fixed
- Fixed account errors not clearing after successful refresh
- Fixed false "No internet connection" message after app launch with transient network issues
- Fixed refresh race condition with debounced label updates
- Fixed empty state flash on app startup
- Fixed infinite recursion crash with equality guards on PRs and grouped PRs collections

### Changed
- Added 3-second delay before triggering refresh on network reconnection (allows DNS/DHCP to fully initialize)
- Improved network error handling to distinguish between cancelled and real errors

### Performance
- Removed dead code and optimized refresh logic
- Static date formatter for better performance
