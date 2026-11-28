import UIKit

/// Vibration, like the web's `navigator.vibrate`: on mistakes and on streaks, never on a plain
/// right answer, and not at all when the player asks for reduced motion (same as the web).
enum Haptics {
    private static var allowed: Bool { !UIAccessibility.isReduceMotionEnabled }

    static func wrong() {
        guard allowed else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func streak(big: Bool) {
        guard allowed else { return }
        if big {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
