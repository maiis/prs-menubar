import SwiftUI

struct ProviderSelectionView: View {

    // MARK: - State
    @State private var selectedProvider: GitProvider = .github
    @State private var showAddAccount = false

    // MARK: - Environment
    @Environment(AppState.self) private var appState

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

            VStack(spacing: 12) {
                ForEach(GitProvider.allCases, id: \.self) { provider in
                    ProviderButton(
                        provider: provider,
                        isSelected: selectedProvider == provider
                    ) {
                        selectedProvider = provider
                    }
                }
            }
            .padding(.vertical)

            Button("Continue") {
                showAddAccount = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 500)
        .sheet(isPresented: $showAddAccount) {
            AddAccountView(provider: selectedProvider, isOnboarding: true)
                .environment(appState)
        }
    }
}

// MARK: - Preview
#Preview {
    ProviderSelectionView()
        .environment(AppState.shared)
}
