import Observation
import SwiftUI

/// The short visual effects of the game screen (the web's FxLayer and HUD flashes), each cleared
/// after the web's duration. A new event restarts it.
@Observable
final class GameFx {
    nonisolated struct Banner: Equatable, Sendable {
        let id: Int
        let streak: Int
        let bonus: Int
        /// A combo bonus was earned: bigger banner and confetti.
        let big: Bool
    }

    private(set) var wrongFlash: Int?
    private(set) var banner: Banner?
    private(set) var hit: (id: Int, amount: Int)?
    private(set) var brokenStreak = false
    @ObservationIgnored private var counter = 0

    /// From this streak on the game cheers (the first combo bonus is at 3).
    static let cheerFrom = 3

    func flashWrong() {
        let id = next()
        wrongFlash = id
        clear(after: .milliseconds(700)) { if $0.wrongFlash == id { $0.wrongFlash = nil } }
    }

    func cheer(streak: Int, bonus: Int) {
        guard streak >= Self.cheerFrom else { return }
        let id = next()
        let big = bonus > 0
        banner = Banner(id: id, streak: streak, bonus: bonus, big: big)
        clear(after: .milliseconds(big ? 2200 : 1500)) { if $0.banner?.id == id { $0.banner = nil } }
    }

    func showHit(_ amount: Int) {
        let id = next()
        hit = (id, amount)
        clear(after: .milliseconds(1400)) { if $0.hit?.id == id { $0.hit = nil } }
    }

    func breakStreak() {
        brokenStreak = true
        clear(after: .milliseconds(900)) { $0.brokenStreak = false }
    }

    private func next() -> Int {
        counter += 1
        return counter
    }

    private func clear(after delay: Duration, _ body: @escaping (GameFx) -> Void) {
        Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard let self else { return }
            body(self)
        }
    }
}
