# Changelog

All notable changes to PRs MenuBar will be documented in this file.

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
