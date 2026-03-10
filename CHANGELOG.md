# Changelog

All notable changes to PRs MenuBar will be documented in this file.

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
