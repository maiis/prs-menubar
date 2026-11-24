import SwiftUI

extension View {
    /// macOS 27 splits `.roundedBorder` into `.bordered` plus an explicit border shape, and
    /// deprecates the old style. Both render the same control.
    @ViewBuilder
    func roundedBorderTextField() -> some View {
        if #available(macOS 27.0, *) {
            textFieldStyle(.bordered)
                .textInputBorderShape(.roundedRectangle)
        } else {
            textFieldStyle(.roundedBorder)
        }
    }
}
