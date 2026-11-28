import Testing
@testable import Contrarreloj

private final class RecordingSink: AnalyticsSink {
    var collection: [Bool] = []
    var consent: [Bool] = []
    var resets = 0
    var logged: [(String, [String: AnalyticsValue])] = []
    func setCollectionEnabled(_ enabled: Bool) { collection.append(enabled) }
    func setAnalyticsConsent(granted: Bool) { consent.append(granted) }
    func resetData() { resets += 1 }
    func log(_ name: String, _ parameters: [String: AnalyticsValue]) { logged.append((name, parameters)) }
}

struct AnalyticsEventTests {
    private let competitive = GameSetup(mode: .competitive, duration: .long, filter: .hard, category: .science)
    private var allEvents: [AnalyticsEvent] {
        [
            .screenView("Inicio"), .loginClick(.google), .loginSuccess(.apple), .loginError(.google, code: "google/-5"),
            .share(method: "native", mode: .arcade), .gameStart(.arcade()), .gameStart(competitive),
            .gameEnd(competitive, GameFixtures.report(rights: 4, duration: .long, filter: .hard, category: .science)),
            .questionReport(.music, .veryEasy), .accountDeleted(.apple),
        ]
    }

    @Test func eventNamesMatchWeb() {
        #expect(allEvents.map(\.name) == [
            "screen_view", "login_click", "login_success", "login_error", "share", "game_start", "game_start",
            "game_end", "question_report", "account_deleted",
        ])
        #expect(AnalyticsEvent.loginError(.google, code: "google/-5").parameters == ["method": .string("google"), "error_code": .string("google/-5")])
        #expect(AnalyticsEvent.share(method: "copy", mode: .competitive).parameters
            == ["method": .string("copy"), "content_type": .string("game_result"), "mode": .string("competitive")])
        #expect(AnalyticsEvent.screenView("Ranking").parameters == ["screen_name": .string("Ranking"), "screen_class": .string("Ranking")])
    }

    @Test func gameStartUsesSlugs() {
        #expect(AnalyticsEvent.gameStart(.arcade()).parameters
            == ["mode": .string("arcade"), "duration": .int(60), "difficulty": .string("aleatorio"), "category": .string("all")])
        #expect(AnalyticsEvent.gameStart(competitive).parameters["category"] == .string("ciencias"))
        #expect(AnalyticsEvent.gameStart(competitive).parameters["difficulty"] == .string("dificil"))
    }

    @Test func gameEndParameters() {
        let report = GameFixtures.report(rights: 4, duration: .long, filter: .hard, category: .science)
        let parameters = AnalyticsEvent.gameEnd(competitive, report).parameters
        #expect(Set(parameters.keys) == ["mode", "duration", "difficulty", "category", "points", "correct", "wrong",
                                         "skipped", "best_streak", "finish_reason"])
        #expect(parameters["points"] == .int(report.points))
        #expect(parameters["correct"] == .int(4))
        #expect(parameters["best_streak"] == .int(4))
        #expect(parameters["finish_reason"] == .string(report.finishReason.rawValue))
        #expect(report.finishReason == .exhausted)
    }

    @Test func noParameterHoldsPersonalData() {
        let forbidden: Set<String> = ["uid", "user_id", "name", "display_name", "email", "photo", "photo_url"]
        for event in allEvents {
            #expect(Set(event.parameters.keys).isDisjoint(with: forbidden), "\(event.name)")
        }
    }

    @Test func trackIsNoOpUntilAccepted() {
        let sink = RecordingSink()
        let analytics = FirebaseAnalyticsService(sink: sink)
        analytics.track(.screenView("Inicio"))
        #expect(sink.logged.isEmpty)

        analytics.apply(.accepted(.now))
        analytics.track(.screenView("Inicio"))
        #expect(sink.logged.map(\.0) == ["screen_view"])
        #expect(sink.collection == [true])
        #expect(sink.consent == [true])

        analytics.apply(.rejected(.now))
        analytics.track(.screenView("Ranking"))
        #expect(sink.logged.count == 1)
        #expect(sink.collection == [true, false])
        #expect(sink.resets == 1)
    }

    @Test func unsetConsentKeepsCollectionOff() {
        let sink = RecordingSink()
        let analytics = FirebaseAnalyticsService(sink: sink)
        analytics.apply(.unset)
        analytics.track(.loginClick(.google))
        #expect(sink.logged.isEmpty)
        #expect(sink.collection == [false])
    }
}
