import SwiftUI

struct ProviderSelectionView: View {

    // MARK: - State
    @State private var selectedProvider: GitProvider = .github
    @State private var showAddAccount = false

    // MARK: - Environment
    @Environment(\.dismissWindow) private var dismissWindow

    // MARK: - UI
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome to PRs Menu Bar")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Select your Git service provider to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("Provider", selection: $selectedProvider) {
                ForEach(GitProvider.allCases) { provider in
                    Label(
                        provider.requiresCustomURL ? "\(provider.displayName) (self-hosted)" : provider.displayName,
                        systemImage: provider.iconName
                    )
                    .tag(provider)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            .padding(.vertical)

            Button("Continue") {
                showAddAccount = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 500)
        .containerBackground(.regularMaterial, for: .window)
        .sheet(isPresented: $showAddAccount) {
            AddAccountView(provider: selectedProvider, isOnboarding: true)
        }
        .onChange(of: showAddAccount) { _, isShowing in
            // When the sheet closes and onboarding is complete, dismiss the onboarding window.
            if !isShowing, AccountManager.shared.hasCompletedOnboarding {
                dismissWindow(id: "onboarding")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProviderSelectionView()
        .environment(AppState.shared)
}
