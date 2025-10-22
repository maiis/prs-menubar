import SwiftUI

struct SettingsView: View {
  @State private var showTokenSheet = false
  @State private var showDeleteConfirmation = false
  @State private var tokenDeleted = false
  @State private var appState = AppState.shared
  @Environment(\.openURL) private var openURL

  var body: some View {
    Form {
      Section {
        LabeledContent("App Version") {
          Text(appVersion)
            .foregroundStyle(.secondary)
        }

        LabeledContent("Bundle ID") {
          Text("me.maiis.prsmenubar")
            .foregroundStyle(.secondary)
            .font(.caption)
        }
      } header: {
        Text("About")
      }

      Section {
        Button("Update GitHub Token") {
          tokenDeleted = false
          showTokenSheet = true
        }

        Button("Delete Token") {
          showDeleteConfirmation = true
        }
        .foregroundStyle(.red)

        if tokenDeleted {
          Label("Token deleted successfully", systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .font(.caption)
        }
      } header: {
        Text("Authentication")
      }

      Section {
        Link(destination: URL(string: "https://buymeacoffee.com/maiis")!) {
          HStack {
            Image(systemName: "cup.and.saucer.fill")
            Text("Buy Me a Coffee")
          }
        }
      } header: {
        Text("Support")
      } footer: {
        Text("If you find this app useful, consider supporting its development!")
          .font(.caption)
      }

      Section {
        Toggle("Demo Mode", isOn: Binding(
          get: { appState.isDemoMode },
          set: { appState.setDemoMode($0) }
        ))
      } header: {
        Text("App Review")
      } footer: {
        Text("Enable demo mode to preview the app with sample pull requests. No GitHub token required.")
          .font(.caption)
      }
    }
    .formStyle(.grouped)
    .frame(width: 500, height: 550)
    .sheet(isPresented: $showTokenSheet) {
      TokenPromptView()
        .environment(AppState.shared)
    }
    .confirmationDialog(
      "Are you sure you want to delete your GitHub token?",
      isPresented: $showDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete Token", role: .destructive) {
        deleteToken()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("You will need to enter a new token to continue using the app.")
    }
  }

  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    return "\(version) (\(build))"
  }

  private func deleteToken() {
    do {
      try KeychainManager.deleteToken()
      tokenDeleted = true
    } catch {
      tokenDeleted = false
    }
  }
}

#Preview {
  SettingsView()
}
