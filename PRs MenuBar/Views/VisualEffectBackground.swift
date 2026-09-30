import AppKit
import SwiftUI

/// Bridges `NSVisualEffectView` so a SwiftUI window can adopt a translucent, vibrant
/// (Liquid Glass) background. The onboarding window isn't glassy by default, unlike the
/// `MenuBarExtra(.window)` popover which the system backs with a material.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context _: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
}
