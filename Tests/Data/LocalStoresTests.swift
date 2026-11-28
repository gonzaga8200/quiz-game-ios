import Foundation
import Testing
@testable import Contrarreloj

private func freshDefaults() -> UserDefaults {
    let name = "tests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

private let now = Date(timeIntervalSince1970: 1_800_000_000)
private let day: TimeInterval = 86_400

struct LocalStoresTests {
    // MARK: Seen memory (port of seen-questions.test.ts)

    @Test func seenUsesTheWebKey() {
        #expect(SeenMemory.key == "contrarreloj.seen.v1")
    }

    @Test func seenCountsIncrementAndForgetUnknownIds() {
        let defaults = freshDefaults()
        let memory = SeenMemory(defaults: defaults)
        #expect(memory.read().isEmpty)
        memory.record(shown: ["a", "b"], bankIds: ["a", "b"])
        memory.record(shown: ["a", "b"], bankIds: ["a", "b"])
        memory.record(shown: ["a"], bankIds: ["a", "b"])
        #expect(memory.read() == ["a": 3, "b": 2])

        memory.record(shown: ["viejo"], bankIds: ["viejo", "a"])
        memory.record(shown: ["a"], bankIds: ["a"])
        #expect(memory.read() == ["a": 4])

        memory.record(shown: ["fantasma"], bankIds: ["a"])
        #expect(memory.read() == ["a": 4])
    }

    @Test(arguments: ["{not json", "[1,2]", "{\"a\":-1}", "{\"a\":1.5}", "{\"a\":\"x\"}", "null", "{\"a\":0}"])
    func corruptSeenReadsEmpty(_ raw: String) {
        let defaults = freshDefaults()
        defaults.set(raw, forKey: SeenMemory.key)
        let memory = SeenMemory(defaults: defaults)
        #expect(memory.read().isEmpty)
        memory.record(shown: ["a"], bankIds: ["a"])
        #expect(memory.read() == ["a": 1])
    }

    // MARK: Consent (port of consent.test.ts)

    @Test func consentFormatMatchesWeb() throws {
        let defaults = freshDefaults()
        let store = ConsentStore(defaults: defaults, now: { now })
        #expect(store.status == .unset)
        #expect(store.needsAsking)
        store.decide(accepted: true)
        #expect(store.status == .accepted(now))
        #expect(!store.needsAsking)

        let raw = try #require(defaults.string(forKey: "contrarreloj.consent"))
        let object = try #require(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
        #expect(object["version"] as? Int == 1)
        #expect(object["choice"] as? String == "accepted")
        #expect(object["decidedAt"] as? Int64 == 1_800_000_000_000)

        store.decide(accepted: false)
        #expect(ConsentStore(defaults: defaults, now: { now }).status == .rejected(now))
    }

    @Test func consentExpiresAfter730Days() {
        let defaults = freshDefaults()
        ConsentStore(defaults: defaults, now: { now }).decide(accepted: true)
        let justBefore = now.addingTimeInterval(730 * day - 0.001)
        #expect(ConsentStore(defaults: defaults, now: { justBefore }).status == .accepted(now))
        let expired = now.addingTimeInterval(730 * day)
        #expect(ConsentStore(defaults: defaults, now: { expired }).status == .unset)
    }

    @Test(arguments: [
        #"{"version":2,"choice":"accepted","decidedAt":1800000000000}"#,
        #"{"version":1,"choice":"maybe","decidedAt":1800000000000}"#,
        #"{"version":1,"choice":"accepted"}"#,
        #"{"version":1,"choice":"accepted","decidedAt":1800000010000}"#,
        #""accepted""#,
        "{nope",
    ])
    func consentWithOtherVersionIsUnset(_ raw: String) {
        let defaults = freshDefaults()
        defaults.set(raw, forKey: "contrarreloj.consent")
        #expect(ConsentStore(defaults: defaults, now: { now }).status == .unset)
    }

    // MARK: Sound and hidden players

    @Test func mutedPersists() {
        let defaults = freshDefaults()
        #expect(!SoundPreference(defaults: defaults).isMuted)
        SoundPreference(defaults: defaults).isMuted = true
        #expect(SoundPreference(defaults: defaults).isMuted)
        #expect(defaults.object(forKey: "contrarreloj.muted") != nil)
    }

    @Test func hiddenPlayersPersist() {
        let defaults = freshDefaults()
        let hidden = HiddenPlayers(defaults: defaults)
        hidden.hide("mallory")
        hidden.hide("eve")
        hidden.unhide("eve")
        #expect(HiddenPlayers(defaults: defaults).uids == ["mallory"])
    }
}
