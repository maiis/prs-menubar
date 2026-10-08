# Privacy Policy for PRs MenuBar

**Last Updated:** September 2026

## Overview

PRs MenuBar is a macOS menu bar application that shows the pull requests (and merge requests) awaiting your review on GitHub, GitLab, and Gitea/Forgejo. This privacy policy explains what data the app accesses, where it is kept, and which servers it talks to.

**We do not collect any data. The app has no servers of its own, and it has no analytics, tracking, or crash reporting.**

## What Data Is Used

Using the access token you provide, the app retrieves the pull requests awaiting your review from each account you add, including:

- Title, number, link, repository, and draft status
- Author username and profile picture address
- Creation and update dates
- Labels and their colors

## Data Storage

- **Access tokens**: Stored in the macOS Keychain (service identifier `me.maiis.prsmenubar`), one entry per account
- **Account settings** (name, provider, server address) and **display preferences**: Stored in the app's local preferences
- **Pull request data**: Held in memory only while the app runs, never written to disk
- **Profile pictures**: Cached in the app's local cache folder to avoid re-downloading them on every refresh; removed when you uninstall the app, and macOS may clear it at any time

## Network Communication

The app connects only to:

- **The Git servers you configure**: `api.github.com`, `gitlab.com` or your self-hosted GitLab, and your Gitea/Forgejo instance
  - Purpose: Fetch pull requests awaiting your review
  - Data sent: The account's access token (HTTP `Authorization` header), sent only to that account's server; a `User-Agent` naming the app and its version
  - Data received: Pull request metadata (see above)
- **Profile picture hosts**: The addresses your Git provider returns for author pictures. These are usually the provider's own servers, but can be third-party avatar services such as [Gravatar](https://gravatar.com), which GitLab and Gitea may use. These requests never include your token, but like any web request they reveal your IP address to that host. Turn this off with **Settings → Display → Show Author Avatars**.

Links you open from the app (a pull request, or the links in the About tab) open in your default web browser.

## Third-Party Services

Your data is exchanged only with the Git providers you configure and, for profile pictures, the hosts described above. See their privacy policies, for example:

- [GitHub Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement)
- [GitLab Privacy Statement](https://about.gitlab.com/privacy/)
- For self-hosted GitLab, Gitea, or Forgejo: the policy of whoever runs that server

## Your Rights

You can:

- **Remove an account** in **Settings → Accounts**, which also deletes its token from the Keychain
- **Turn off profile pictures** in **Settings → Display**
- **Revoke a token** at any time from your Git provider's settings
- **Delete all app data** by removing your accounts and uninstalling the app

## Open Source

This app is open source. You can review the complete source code at:
https://github.com/maiis/prs-menubar

## App Permissions

The app requires:

- **Network Access** (outgoing only): To communicate with your Git providers and load profile pictures
- **Keychain Access**: To securely store your access tokens

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

- **Consent**: By providing an access token, you consent to the app using it
- **Legitimate Interest**: Operating the app's core functionality

You have the right to withdraw consent at any time by deleting your token or uninstalling the app.
