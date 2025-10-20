import SwiftUI

struct SettingsView: View {
  @State private var showTokenSheet = false
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
          showTokenSheet = true
        }

        Button("Delete Token") {
          deleteToken()
        }
        .foregroundStyle(.red)
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
    }
    .formStyle(.grouped)
    .frame(width: 450, height: 400)
    .sheet(isPresented: $showTokenSheet) {
      TokenPromptView()
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
    } catch {
    }
  }
}

#Preview {
  SettingsView()
}
