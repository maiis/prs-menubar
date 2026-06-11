# GitHub Releases Setup Guide

This guide explains how to set up automated GitHub releases with code signing and notarization for PRs MenuBar.

## Overview

The release workflow automatically:
1. Builds the app when a version tag is pushed
2. Signs the app with your Developer ID certificate
3. Notarizes the app with Apple
4. Creates a DMG installer
5. Uploads the DMG to GitHub Releases

## Prerequisites

Before you can use the automated release workflow, you need:

1. **Apple Developer Account** ($99/year)
2. **Developer ID Application Certificate** from Apple
3. **App-Specific Password** for notarization

## Setup Instructions

### 1. Create a Developer ID Application Certificate

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click the "+" button to create a new certificate
3. Select "Developer ID Application" 
4. Follow the instructions to create a Certificate Signing Request (CSR) using Keychain Access
5. Upload the CSR and download your certificate
6. Double-click the certificate to install it in your Keychain

### 2. Export Your Certificate

1. Open **Keychain Access** on your Mac
2. Find your "Developer ID Application" certificate
3. Right-click and select "Export..."
4. Save as a `.p12` file with a strong password
5. Keep this password safe - you'll need it later

### 3. Create an App-Specific Password

1. Go to [Apple ID Account](https://appleid.apple.com/account/manage)
2. Sign in with your Apple ID
3. In the "Security" section, under "App-Specific Passwords", click "Generate Password..."
4. Enter a label like "PRs MenuBar Notarization"
5. Copy the generated password - you'll need it for GitHub secrets

### 4. Configure GitHub Secrets

Go to your GitHub repository settings and add the following secrets:

#### Required Secrets

1. **BUILD_CERTIFICATE_BASE64**
   - Convert your `.p12` file to base64:
   ```bash
   base64 -i YourCertificate.p12 | pbcopy
   ```
   - Paste the output as the secret value

2. **P12_PASSWORD**
   - The password you used when exporting the `.p12` file

3. **KEYCHAIN_PASSWORD**
   - Create a strong random password for the temporary keychain
   - Example: `openssl rand -base64 32`

4. **DEVELOPMENT_TEAM**
   - Your Apple Developer Team ID
   - Find it at [developer.apple.com/account](https://developer.apple.com/account) under "Membership"
   - Format: 10 alphanumeric characters (e.g., `AR3H59SG7B`)

5. **APPLE_ID**
   - Your Apple ID email address
   - Example: `developer@example.com`

6. **APPLE_ID_PASSWORD**
   - The app-specific password you created in step 3

7. **APPLE_TEAM_ID**
   - Same as DEVELOPMENT_TEAM (your Apple Developer Team ID)

**Note:** The workflow automatically updates the `exportOptions.plist` file with your team ID from the `DEVELOPMENT_TEAM` secret, so you don't need to manually edit it.

## Creating a Release

Once everything is set up, creating a release is simple:

### 1. Update Version Number

Update the `MARKETING_VERSION` in the Xcode project:
1. Open `PRs MenuBar.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "PRs MenuBar" target
4. Go to the "General" tab
5. Update the "Version" field (e.g., `1.4.0`)

Or edit the version directly in the project file:
```bash
# Find and update MARKETING_VERSION in PRs MenuBar.xcodeproj/project.pbxproj
```

Also bump the build number (`CURRENT_PROJECT_VERSION`) so each release has a unique,
monotonically increasing build. It must increase on every release (App Store rejects
duplicate build numbers, and update tooling compares them):
```bash
# Increment CURRENT_PROJECT_VERSION in PRs MenuBar.xcodeproj/project.pbxproj
# (currently shared across all configs; bump it to the next integer)
```

### 2. Update RELEASE_NOTES.md

Add user-friendly release notes for the new version:

```markdown
## Version 1.5

What's new in this release:

• New feature description in user-friendly language
• Bug fixes and improvements
```

### 3. Commit Changes

```bash
git add .
git commit -m "Bump version to 1.4.0"
git push
```

### 4. Create and Push a Tag

```bash
git tag v1.4.0
git push origin v1.4.0
```

### 5. Wait for the Build

The release workflow will automatically:
- Build the app (~5 minutes)
- Notarize with Apple (~5-10 minutes)
- Create a GitHub release with the DMG

You can monitor progress in the "Actions" tab of your GitHub repository.

## Distributing the Release

Once the release is complete:

1. Go to your GitHub repository's "Releases" page
2. Find the newly created release
3. Edit the release notes if needed
4. Share the download link with users

Users can download the DMG, drag the app to their Applications folder, and it will run without security warnings because it's notarized.

## Troubleshooting

### Certificate Issues

If you get certificate-related errors:
- Verify your certificate is valid and not expired
- Ensure the base64 encoding is correct (no extra spaces or newlines)
- Check that P12_PASSWORD matches the password used during export

### Notarization Failures

If notarization fails:
- Verify APPLE_ID and APPLE_ID_PASSWORD are correct
- Ensure you're using an app-specific password, not your main Apple ID password
- Check that APPLE_TEAM_ID matches your Developer Team ID
- Review the notarization logs in the GitHub Actions output

### Build Failures

If the build fails:
- Ensure your Xcode project builds locally first
- Verify DEVELOPMENT_TEAM is set correctly
- Check that the scheme "PRs MenuBar" exists and is shared

## Security Best Practices

1. **Never commit certificates or passwords** to the repository
2. **Use strong passwords** for P12 and keychain
3. **Rotate app-specific passwords** periodically
4. **Limit repository access** to trusted collaborators
5. **Review Actions logs** to ensure no secrets are exposed

## Manual Release (Alternative)

If you prefer to create releases manually:

1. Build the app in Xcode (Product → Archive)
2. Export with "Developer ID" distribution
3. Notarize using `xcrun notarytool`
4. Create a DMG with `create-dmg` or Disk Utility
5. Upload to GitHub Releases manually

For detailed manual instructions, see [Apple's Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).
