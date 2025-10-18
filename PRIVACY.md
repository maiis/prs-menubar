# Privacy Policy for PRs MenuBar

**Last Updated:** January 2025

## Overview

PRs MenuBar is a macOS menu bar application that helps you track GitHub pull requests awaiting your review. This privacy policy explains how the app handles your data.

## Data Collection

**We do not collect, store, or transmit any personal data to third parties.**

### What Data is Used

The app uses the following data locally on your device:

1. **GitHub Personal Access Token**
   - Stored securely in macOS Keychain
   - Used exclusively to authenticate with GitHub's API
   - Never transmitted to anyone except GitHub's official API endpoints

2. **GitHub Pull Request Data**
   - Fetched from GitHub's API using your token
   - Stored temporarily in memory while the app is running
   - Used only to display your pending review requests
   - Not persisted to disk or shared with any third parties

## Data Storage

- **GitHub Token**: Stored in macOS Keychain with service identifier `me.maiis.prsmenubar`
- **PR Data**: Stored temporarily in memory, cleared when app quits
- **No Analytics**: We don't collect usage data, crash reports, or analytics

## Network Communication

The app communicates exclusively with:

- **GitHub API** (`api.github.com`)
  - Purpose: Fetch pull requests awaiting your review
  - Data sent: Your GitHub Personal Access Token (via HTTP Authorization header)
  - Data received: Pull request metadata (titles, URLs, repository names)

**No other network connections are made.**

## Third-Party Services

The app uses only one third-party service:

- **GitHub API**: For fetching pull request data. See [GitHub's Privacy Policy](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement)

## Your Rights

You can:

- **Delete your token** at any time by quitting the app and removing it from macOS Keychain
- **Revoke API access** by deleting the Personal Access Token from GitHub settings
- **Uninstall the app** completely by deleting it from your Applications folder

## Open Source

This app is open source. You can review the complete source code at:
https://github.com/maiis/prs-menubar

## App Permissions

The app requires:

- **Network Access**: To communicate with GitHub's API
- **Keychain Access**: To securely store your GitHub token

The app runs in the **macOS App Sandbox** with minimal permissions.

## Changes to This Policy

We may update this privacy policy from time to time. Changes will be reflected in the "Last Updated" date above and posted in the repository.

## Contact

For privacy concerns or questions:

- Open an issue: https://github.com/maiis/prs-menubar/issues
- Email: apps@maiis.me

## Children's Privacy

This app is not directed to children under 13. We do not knowingly collect information from children.

## Legal Basis (GDPR)

For users in the EU/EEA, our legal basis for processing is:

- **Consent**: By providing your GitHub token, you consent to the app using it
- **Legitimate Interest**: Operating the app's core functionality

You have the right to withdraw consent at any time by deleting your token or uninstalling the app.
