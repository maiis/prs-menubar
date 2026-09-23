import SwiftUI

/// Bridges macOS 27's `systemPrefersReducedResourceUsage` into `AppState`.
///
/// The value is gated to macOS 27, so it can't be declared with `@Environment` on a type that also
/// compiles for macOS 15. This zero-sized view isolates the annotation.
@available(macOS 27.0, *)
private struct ReducedResourceUsageReader: View {

    // MARK: - Environment
    @Environment(\.systemPrefersReducedResourceUsage) private var prefersReducedResourceUsage

    // MARK: - Properties
    let onChange: (Bool) -> Void

    // MARK: - UI
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear { onChange(prefersReducedResourceUsage) }
            .onChange(of: prefersReducedResourceUsage) { _, newValue in
                onChange(newValue)
            }
    }
}

extension View {
    /// Attach to a view that lives for the whole session — the menu bar label, not the popover
    /// content, which doesn't exist until the user first opens the panel.
    @ViewBuilder
    func reportsReducedResourceUsage(_ onChange: @escaping (Bool) -> Void) -> some View {
        if #available(macOS 27.0, *) {
            background(ReducedResourceUsageReader(onChange: onChange))
        } else {
            self
        }
    }
}
