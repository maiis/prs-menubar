import SwiftUI

struct SettingsView: View {
  @State private var showTokenSheet = false

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
    }
    .formStyle(.grouped)
    .frame(width: 400, height: 300)
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
      print("Failed to delete token: \(error)")
    }
  }
}

#Preview {
  SettingsView()
}
