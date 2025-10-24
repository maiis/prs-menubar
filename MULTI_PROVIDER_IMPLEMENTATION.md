# Multi-Provider Support Implementation Summary

## Overview
This implementation adds support for multiple Git service providers (GitHub, GitLab, and Gitea) to the PRs Menu Bar app, allowing users to track pull requests across different platforms and manage multiple accounts.

## Architecture Changes

### New Models
1. **GitProvider** (`Models/GitProvider.swift`)
   - Enum representing supported providers: GitHub, GitLab, Gitea
   - Provides default URLs, icons, and configuration for each provider
   - Indicates whether custom URLs are required (e.g., for Gitea)

2. **ProviderAccount** (`Models/ProviderAccount.swift`)
   - Represents a configured account for a Git provider
   - Stores provider type, account name, base URL, and enabled state
   - Generates unique keychain identifiers for token storage

### New Services
1. **GitLabService** (`GitLabService.swift`)
   - Implements `GitHubServiceProtocol` for GitLab
   - Uses GitLab REST API v4 to fetch merge requests
   - Queries for MRs where current user is a reviewer

2. **GiteaService** (`GiteaService.swift`)
   - Implements `GitHubServiceProtocol` for Gitea
   - Uses Gitea REST API v1 to fetch pull requests
   - Supports self-hosted Gitea instances

3. **GitServiceFactory** (`GitServiceFactory.swift`)
   - Factory pattern to create appropriate service instance based on provider
   - Injects tokens and base URLs into services

### Account Management
1. **AccountManager** (`AccountManager.swift`)
   - Singleton service for managing provider accounts
   - Handles CRUD operations for accounts
   - Manages token storage/retrieval via KeychainManager
   - Implements onboarding state tracking
   - Migrates legacy GitHub tokens automatically

### Updated Components
1. **KeychainManager** (enhanced)
   - Extended to support multiple accounts with unique identifiers
   - Maintains backward compatibility with legacy single-token approach
   - New methods: `saveToken(_:for:)`, `getToken(for:)`, `deleteToken(for:)`

2. **AppState** (enhanced)
   - Now aggregates PRs from all enabled accounts
   - Fetches from multiple providers concurrently
   - Continues to support demo mode for testing
   - New property: `accounts` to track configured accounts
   - New method: `reloadAccounts()` to refresh account list

3. **PullRequest Model** (enhanced)
   - Updated `repositoryName` computed property to handle different URL patterns:
     - GitHub: `github.com/owner/repo/pull/123`
     - GitLab: `gitlab.com/owner/repo/-/merge_requests/123`
     - Gitea: `gitea.example.com/owner/repo/pulls/123`

## User Interface

### Onboarding Flow
1. **ProviderSelectionView** (`Views/ProviderSelectionView.swift`)
   - First-run onboarding screen
   - Allows users to select their Git provider
   - Shows provider options with icons and descriptions
   - Transitions to account setup

2. **AddAccountView** (`Views/AddAccountView.swift`)
   - Provider-specific account configuration
   - Fields: account name, server URL (for self-hosted), access token
   - Validates tokens before saving
   - Supports both adding new accounts and editing existing ones
   - Provider-specific guidance for token creation

3. **AccountsListView** (`Views/AccountsListView.swift`)
   - Account management interface in Settings
   - List view with toggle to enable/disable accounts
   - Edit and delete actions for each account
   - Add button with provider selection menu

### Updated Views
1. **SettingsView** (enhanced)
   - Integrated AccountsListView
   - Removed legacy single-token management
   - Increased window size to accommodate account list
   - Improved organization with account section at top

2. **PRsMenuBarApp** (enhanced)
   - Shows onboarding on first launch if no accounts configured
   - Replaced legacy token prompt with new onboarding flow
   - New window: "Get Started" for onboarding

## Data Migration

### Backward Compatibility
- Automatic migration of existing GitHub tokens
- Legacy tokens are detected on first run
- Converted to a new GitHub account with default settings
- Onboarding is marked as complete for migrated users
- No data loss during migration

## Security Considerations

### Token Storage
- Each account has a unique keychain identifier (UUID-based)
- Tokens remain encrypted in macOS Keychain
- Service identifier: `me.maiis.prsmenubar`
- Account identifiers: `token-{UUID}`

### API Security
- All requests use HTTPS
- Tokens transmitted via Authorization headers
- Timeout protections (10s for validation, 30s for API calls)
- Error handling for unauthorized/forbidden responses

## Testing

### New Tests (`MultiProviderTests.swift`)
- GitProvider enum properties and behavior
- ProviderAccount creation and uniqueness
- AccountManager CRUD operations
- URL parsing for different providers (GitHub, GitLab, Gitea)
- Keychain identifier uniqueness

### Existing Tests
- Remain compatible with new architecture
- Continue to use mock services for testing
- No breaking changes to test infrastructure

## Provider-Specific Details

### GitHub
- Uses existing GraphQL API implementation
- Search query: `is:pr is:open review-requested:@me`
- Token scope: `repo`
- Default URL: `https://api.github.com`

### GitLab
- REST API v4 endpoint: `/merge_requests`
- Query parameters: `scope=all&state=opened&reviewer_username=@me`
- Token scope: `read_api`
- Default URL: `https://gitlab.com/api/v4`
- Supports self-hosted instances

### Gitea
- REST API v1 endpoint: `/repos/issues/search`
- Query parameters: `type=pulls&state=open&review_requested=true`
- Token scope: `read:repository`
- Requires custom URL (no default)
- Self-hosted only

## Benefits

1. **Multi-Platform Support**: Track PRs across GitHub, GitLab, and Gitea
2. **Multiple Accounts**: Manage work and personal accounts separately
3. **Self-Hosted Support**: GitLab and Gitea self-hosted instances supported
4. **Unified View**: All PRs in one place regardless of provider
5. **Flexible Management**: Enable/disable accounts without deletion
6. **Smooth Migration**: Existing users upgraded automatically

## Future Enhancements (Not Implemented)

Potential future additions could include:
- Bitbucket support
- Azure DevOps support
- Per-account notification settings
- Provider-specific filtering options
- Account groups/categories
- Import/export account configurations
