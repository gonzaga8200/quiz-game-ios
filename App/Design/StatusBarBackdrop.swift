import SwiftUI

/// Covers the status bar area with the page colour, so scrolled content never runs under the clock.
struct StatusBarBackdrop: View {
    var body: some View {
        VStack {
            Color.ground.frame(height: 0).ignoresSafeArea(edges: .top)
            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
