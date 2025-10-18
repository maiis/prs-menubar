# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in PRs MenuBar, please report it responsibly.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, use one of these methods:

1. **GitHub Security Advisories** (Preferred)
   - Go to https://github.com/maiis/prs-menubar/security/advisories/new
   - Click "Report a vulnerability"
   - Provide detailed information about the vulnerability

2. **Email**
   - Send details to: apps@maiis.me
   - Use subject: `[SECURITY] PRs MenuBar - Brief Description`

### What to Include

Please include the following information in your report:

- **Description**: Brief summary of the vulnerability
- **Impact**: What could an attacker do with this vulnerability?
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Proof of Concept**: Code, screenshots, or examples demonstrating the vulnerability
- **Suggested Fix**: If you have ideas on how to fix it (optional)
- **Your Environment**:
  - App version
  - macOS version
  - Any relevant configuration

### What to Expect

- **Acknowledgment**: We'll acknowledge receipt within 48 hours
- **Investigation**: We'll investigate and validate the report
- **Updates**: We'll keep you informed of our progress
- **Resolution**: We'll work on a fix and release it as soon as possible
- **Credit**: We'll credit you in the release notes (unless you prefer to remain anonymous)

### Security Best Practices

PRs MenuBar follows these security practices:

- **Keychain Storage**: GitHub tokens are stored securely in macOS Keychain
- **App Sandbox**: The app runs in macOS App Sandbox with minimal permissions
- **HTTPS Only**: All API communications use HTTPS
- **No Data Collection**: No analytics or telemetry data is collected
- **Open Source**: All code is publicly reviewable

### Scope

Security issues we're interested in:

- Token leakage or insecure storage
- API credential exposure
- Code injection vulnerabilities
- Sandbox escape attempts
- Privilege escalation
- Unauthorized data access

### Out of Scope

- Social engineering attacks
- Physical access attacks
- Issues in third-party dependencies (report to the dependency maintainers)
- Issues requiring user to disable macOS security features

## Disclosure Policy

- We'll coordinate disclosure timing with you
- We prefer coordinated disclosure after a fix is released
- We'll credit researchers who report valid vulnerabilities
- We ask for a reasonable timeframe to fix issues before public disclosure

## Security Updates

Security updates will be released as patch versions and announced in:

- GitHub Releases
- CHANGELOG.md
- Security Advisories (for critical issues)

Thank you for helping keep PRs MenuBar and its users safe!
