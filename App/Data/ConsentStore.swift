import Foundation
import Observation

nonisolated enum ConsentStatus: Equatable, Sendable {
    case unset
    case accepted(Date)
    case rejected(Date)

    var allowsAnalytics: Bool {
        if case .accepted = self { return true }
        return false
    }
}

/// The player's analytics decision, stored like the web's `contrarreloj.consent`
/// (`{"version":1,"choice":"accepted","decidedAt":<ms>}`) and asked again after 24 months or
/// when the policy version changes.
@Observable
final class ConsentStore {
    static let key = "contrarreloj.consent"
    static let version = 1
    static let maxAge: TimeInterval = 730 * 86_400

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    private(set) var status: ConsentStatus

    var needsAsking: Bool { status == .unset }

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
        status = Self.read(defaults, now: now())
    }

    func decide(accepted: Bool) {
        let at = now()
        let milliseconds = Int64((at.timeIntervalSince1970 * 1000).rounded())
        let record: [String: Any] = ["version": Self.version, "choice": accepted ? "accepted" : "rejected", "decidedAt": milliseconds]
        if let data = try? JSONSerialization.data(withJSONObject: record, options: .sortedKeys) {
            defaults.set(String(decoding: data, as: UTF8.self), forKey: Self.key)
        }
        status = accepted ? .accepted(at) : .rejected(at)
    }

    private static func read(_ defaults: UserDefaults, now: Date) -> ConsentStatus {
        guard let raw = defaults.string(forKey: key),
              let object = try? JSONSerialization.jsonObject(with: Data(raw.utf8), options: .fragmentsAllowed) as? [String: Any],
              (object["version"] as? NSNumber)?.intValue == version,
              let choice = object["choice"] as? String,
              let decidedAt = (object["decidedAt"] as? NSNumber)?.doubleValue
        else { return .unset }
        let date = Date(timeIntervalSince1970: decidedAt / 1000)
        let age = now.timeIntervalSince(date)
        guard age >= 0, age < maxAge else { return .unset }
        switch choice {
        case "accepted": return .accepted(date)
        case "rejected": return .rejected(date)
        default: return .unset
        }
    }
}
