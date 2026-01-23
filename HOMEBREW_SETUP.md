# Homebrew Setup Instructions

## Files Already Created

### 1. In Main Repository (prs-menubar)
- ✅ `.github/workflows/update-homebrew-cask.yml` - Auto-update workflow
- ✅ `README.md` - Updated with Homebrew installation instructions

### 2. Ready for Tap Repository
Files prepared in `/tmp/homebrew-prs-menubar/`:
- `Casks/prs-menubar.rb` - Cask formula (v1.5.1)
- `README.md` - Tap documentation

## Next Steps

### 1. Create Tap Repository

```bash
cd /tmp/homebrew-prs-menubar
git init
git add .
git commit -m "Initial commit: Add prs-menubar cask formula"
git remote add origin https://github.com/maiis/homebrew-prs-menubar.git
git push -u origin main
```

### 2. Configure GitHub Secret

For automated cask updates to work:

1. Create Personal Access Token:
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select `public_repo` scope
   - Generate and copy the token

2. Add to main repository:
   - Go to https://github.com/maiis/prs-menubar/settings/secrets/actions
   - Click "New repository secret"
   - Name: `HOMEBREW_GITHUB_TOKEN`
   - Value: [paste token]

### 3. Test Installation

```bash
# Add tap
brew tap maiis/prs-menubar

# Install
brew install --cask prs-menubar

# Verify
open -a "PRs MenuBar"

# Test livecheck
brew livecheck --cask prs-menubar
```

## How Automation Works

When you publish a new release (e.g., v1.6):

1. GitHub Action triggers automatically
2. Downloads new DMG and calculates SHA256
3. Creates PR to `homebrew-prs-menubar` repository
4. You review and merge the PR
5. Users can upgrade: `brew upgrade --cask prs-menubar`

## Cask Formula Details

**Current version:** 1.5.1
**SHA256:** `d5098b136ac4aef94b0afd82d3a7ccf8fba86ab5e36c4c6ff311119fe14dc8e3`

**DMG URL pattern:** `https://github.com/maiis/prs-menubar/releases/download/v#{version}/PRsMenuBar-#{version}.dmg`

**Requirements:**
- macOS 15.0 (Sequoia) or later

**Zap locations:**
- `~/Library/Application Support/PRs MenuBar`
- `~/Library/Preferences/me.maiis.prsmenubar.plist`
- `~/Library/HTTPStorages/me.maiis.prsmenubar`
- `~/Library/Caches/me.maiis.prsmenubar`

## Manual Update Process (Fallback)

If automation fails, update manually:

```bash
cd ~/homebrew-prs-menubar

# Download and calculate SHA256
curl -L -o /tmp/PRsMenuBar-X.X.X.dmg \
  https://github.com/maiis/prs-menubar/releases/download/vX.X.X/PRsMenuBar-X.X.X.dmg
shasum -a 256 /tmp/PRsMenuBar-X.X.X.dmg

# Edit Casks/prs-menubar.rb
# - Update version = "X.X.X"
# - Update sha256 = "new_checksum"

# Commit and push
git add Casks/prs-menubar.rb
git commit -m "Update prs-menubar to X.X.X"
git push
```

## Verification Checklist

- [ ] Tap repository created on GitHub
- [ ] Cask formula syntax valid (Ruby)
- [ ] SHA256 matches DMG file
- [ ] HOMEBREW_GITHUB_TOKEN secret configured
- [ ] Fresh install works
- [ ] App launches correctly
- [ ] Livecheck detects latest version
- [ ] Automated workflow tested with new release

## User Installation Commands

Users will install with:

```bash
brew tap maiis/prs-menubar
brew install --cask prs-menubar
```

Update with:

```bash
brew upgrade --cask prs-menubar
```

Uninstall with:

```bash
# Standard uninstall
brew uninstall prs-menubar

# Complete removal (including preferences)
brew uninstall --zap prs-menubar
```

## Files Location

**Tap repository files:** `/tmp/homebrew-prs-menubar/`
- Casks/prs-menubar.rb
- README.md

Copy these to your new GitHub repository when ready.

## References

- Homebrew Cask Cookbook: https://docs.brew.sh/Cask-Cookbook
- How to Create a Tap: https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
- brew bump-cask-pr: https://docs.brew.sh/Manpage#bump-cask-pr-options-cask
