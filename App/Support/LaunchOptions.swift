import Foundation

/// Launch arguments for UI tests and the emulator integration tests. In the App Store build nobody
/// passes them, so the app runs live.
struct LaunchOptions {
    var uiTesting = false
    var noFirebase = false
    var useEmulators = false
    var seed: UInt32?
    /// `tiny` (6 known questions), `failing` (no questions at all); default: the bundled bank.
    var bank: String?
    /// Start signed in with a fake account of this provider.
    var fakeUser: AuthProvider?
    /// `seeded`, `empty` or `failing`.
    var rankingFake: String?
    /// `accepted`, `rejected` or `unset` (UI tests default to `rejected`, so the card stays away).
    var consent: String?
    /// Longer answer feedback, so a UI test can observe the 600 ms states (stamp, ticks).
    var feedbackMs: Int?

    static let current = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String]) {
        var index = 0
        func value() -> String? {
            index += 1
            return index < arguments.count ? arguments[index] : nil
        }
        while index < arguments.count {
            switch arguments[index] {
            case "-uiTesting": uiTesting = true
            case "-noFirebase": noFirebase = true
            case "-useEmulators": useEmulators = true
            case "-seed": seed = value().flatMap { UInt32($0) }
            case "-bank": bank = value()
            case "-fakeUser": fakeUser = value().flatMap(AuthProvider.init(rawValue:))
            case "-rankingFake": rankingFake = value()
            case "-consent": consent = value()
            case "-feedbackMs": feedbackMs = value().flatMap { Int($0) }
            default: break
            }
            index += 1
        }
    }
}
