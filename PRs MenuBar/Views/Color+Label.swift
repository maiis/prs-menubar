import SwiftUI

extension Color {
    /// Parses a label hex string ("d73a4a"; `labelColorMap` has already stripped any "#") into a
    /// fill color and a legible text color (black or white) chosen by perceived luminance.
    /// Returns nil for bad input.
    static func labelPair(hex: String) -> (fill: Color, text: Color)? {
        let string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // The digit check is not redundant: UInt64(_:radix:) also accepts a leading "+" or "-".
        guard string.count == 6,
              string.allSatisfy(\.isHexDigit),
              let value = UInt64(string, radix: 16) else { return nil }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        let fill = Color(.sRGB, red: red, green: green, blue: blue)
        return (fill, luminance > 0.6 ? .black : .white)
    }
}
