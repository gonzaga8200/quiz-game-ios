import Foundation
import Observation

/// Ranking players this device chose to hide (moderation, Guideline 1.2), with the name they had,
/// so Ajustes can list them. Only on this device.
@Observable
final class HiddenPlayers {
    static let key = "contrarreloj.hiddenPlayers"
    @ObservationIgnored private let defaults: UserDefaults
    /// uid → display name when hidden.
    private(set) var players: [String: String]

    var uids: Set<String> { Set(players.keys) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        players = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
    }

    func hide(_ uid: String, name: String = "") {
        players[uid] = name
        save()
    }

    func unhide(_ uid: String) {
        players[uid] = nil
        save()
    }

    private func save() {
        defaults.set(players, forKey: Self.key)
    }
}
