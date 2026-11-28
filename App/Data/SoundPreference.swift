import Foundation
import Observation

/// Whether the player muted the game sounds (the web's `contrarreloj.muted`).
@Observable
final class SoundPreference {
    static let key = "contrarreloj.muted"
    @ObservationIgnored private let defaults: UserDefaults

    var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: Self.key) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isMuted = defaults.bool(forKey: Self.key)
    }
}
