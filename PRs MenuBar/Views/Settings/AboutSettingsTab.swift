import AppKit
import SwiftUI

struct AboutSettingsTab: View {

    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    if let appIcon = NSImage(named: NSImage.applicationIconName) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .padding(.top, 16)
                    }

                    Text("PRs MenuBar")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 8) {
                        LabeledContent("Version") {
                            Text(appVersion)
                                .foregroundStyle(.secondary)
                        }

                        LabeledContent("Bundle ID") {
                            Text("me.maiis.prsmenubar")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }

            if let destination = URL(string: "https://buymeacoffee.com/maiis") {
                Section {
                    Link(destination: destination) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundStyle(.orange)
                            Text("Buy Me a Coffee")
                        }
                    }
                } header: {
                    Text("Support")
                        .font(.headline)
                } footer: {
                    Text("If you find this app useful, consider supporting its development!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("A menu bar app for tracking pull requests across GitHub, GitLab, and Gitea.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } header: {
                Text("About")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Getters
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview
#Preview {
    AboutSettingsTab()
        .frame(width: 550, height: 450)
}
