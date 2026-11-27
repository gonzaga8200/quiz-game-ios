import Foundation

/// What this device has been shown: question id to how many times (the web's
/// `contrarreloj.seen.v1`). The game serves the least seen first, so repeats come as late as
/// possible. It never leaves the device; if it is missing or corrupt the game starts afresh.
struct SeenMemory {
    static let key = "contrarreloj.seen.v1"
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func read() -> [String: Int] {
        guard let raw = defaults.string(forKey: Self.key),
              let object = try? JSONSerialization.jsonObject(with: Data(raw.utf8), options: .fragmentsAllowed) as? [String: Any]
        else { return [:] }
        var counts: [String: Int] = [:]
        for (id, value) in object {
            // Like the web schema: positive integers only, or the whole memory is discarded.
            guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
                  number.doubleValue == number.doubleValue.rounded(), number.intValue > 0
            else { return [:] }
            counts[id] = number.intValue
        }
        return counts
    }

    /// Adds one to every shown id and forgets ids that are no longer in the bank.
    func record(shown: [String], bankIds: Set<String>) {
        var counts = read()
        for id in shown { counts[id, default: 0] += 1 }
        counts = counts.filter { bankIds.contains($0.key) }
        guard let data = try? JSONSerialization.data(withJSONObject: counts, options: .sortedKeys) else { return }
        defaults.set(String(decoding: data, as: UTF8.self), forKey: Self.key)
    }
}
