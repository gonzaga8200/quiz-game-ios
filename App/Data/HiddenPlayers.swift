import Foundation
import Observation

/// Ranking players this device chose to hide (moderation, Guideline 1.2). Only on this device.
@Observable
final class HiddenPlayers {
    static let key = "contrarreloj.hiddenPlayers"
    @ObservationIgnored private let defaults: UserDefaults
    private(set) var uids: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        uids = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func hide(_ uid: String) {
        uids.insert(uid)
        save()
    }

    func unhide(_ uid: String) {
        uids.remove(uid)
        save()
    }

    private func save() {
        defaults.set(uids.sorted(), forKey: Self.key)
    }
}
