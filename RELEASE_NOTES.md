# Release Notes

## 1.7

Fixed the menu crash and made errors actually useful.

- No more infinite loop crash when opening the menu
- Better network error messages (timeout vs DNS vs actually offline)
- Smarter offline detection (won't lie to you when it's just a slow connection)

Your app now knows the difference between "no internet" and "GitHub is having a moment."

---

## 1.6

Fixed embarrassing bugs where the app would hit APIs twice for no reason.

- No more double refreshes when managing accounts
- Fixed race conditions (timer vs network vs you)
- Accounts won't orphan if token save fails
- Better error cleanup

Your app now refreshes once per refresh. Revolutionary.

---

## 1.5

The "We Actually Tell You What's Wrong Now" release.

Ever had the app just... quit? And you're left wondering what happened? Yeah, we fixed that. Now everything gets logged properly so you (or we) can actually figure out what went wrong.

What's new:
- Offline detection: No more confusing errors when your WiFi decides to take a break. We'll tell you you're offline and let you retry when you're back.
- Network retry: Flaky connection? API having a moment? We'll retry automatically with exponential backoff. Fancy words for "we try again, but politely."
- Provider-specific errors: "GitHub said no" vs "GitLab said no" — finally, blame the right service.
- No accounts? No problem: Instead of showing a sad "0 PRs" when you haven't set up anything, we now show a helpful "hey, add an account" message.
- Smarter menu bar icon: Shows a question mark person when no accounts configured, not a misleading checkmark.

Under the hood:
- Comprehensive logging with os.Logger (Console.app is your new friend)
- Atomic keychain operations (your tokens are safer)
- Silent failures are no longer silent

Basically, we made the app tell you what's happening instead of just... not.

---

## 1.4

We made your menu bar happier (and faster).

What's improved:
- Lightning-fast PR loading with smarter caching
- Reduced memory usage
- More reliable refresh cycles
- Better error handling

Basically, same great app, just faster and more reliable. Like switching from coffee to espresso.

---

## 1.3

We heard you have accounts EVERYWHERE. GitHub? Sure. GitLab? Why not. Self-hosted Gitea? Bring it on.

Now you can track PRs from ALL your Git providers in one place. Add as many accounts as you want—work GitHub, personal GitHub, that one GitLab your client insists on, your company's Gitea instance... we don't judge.

What's new:
- Multi-provider support (GitHub, GitLab, Gitea/Forgejo)
- Unlimited accounts (seriously, go wild)
- Each account gets its own token (secure AF)
- Fetch from all accounts at once (hello, concurrency)
- Filter by labels (exclude those pesky "dependencies" PRs)
- Provider-specific icons (because aesthetics matter)

We also fixed a bunch of behind-the-scenes stuff so your PR IDs stay stable and your menu bar doesn't lie to you anymore.

Basically, we took "works with GitHub" and turned it into "works with everything that has PRs."

You're welcome.

---

## 1.2

Your PRs Got Smarter:
- Launch at login
- Sort however you want
- Hide those "still WIP" drafts
- Group by repo
- Refresh faster (or slower)

Oh, and we switched to GitHub's GraphQL API, so no more phantom PRs playing peek-a-boo with you. They can't hide anymore.

Basically, we turned your PR notifications from "meh" to "YES!"

---

## 1.1

• Lowered the bouncer's age check - now works on macOS 14.6+
• Fixed errors actually being helpful instead of mysterious
• Bug fixes (they were very smol bugs, barely worth mentioning)

---

## 1.0

Initial release:

• View pull requests awaiting your review directly from the menu bar
• See PR count at a glance with menu bar icon
• Secure token storage using macOS Keychain
• Auto-refresh every 10 minutes to stay up to date
• One-click access to open PRs in your browser
• Manual refresh with ⌘R keyboard shortcut
• Clean, native macOS interface built with SwiftUI
