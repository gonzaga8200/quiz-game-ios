import Foundation
import Testing
@testable import Contrarreloj

/// A sound player that records what it was asked to do.
final class RecordingPlayer: SoundPlayer {
    private(set) var calls: [String] = []
    func prepare() { calls.append("prepare") }
    func play(_ sound: SoundName) { calls.append("play:\(sound)") }
}

struct PlayCoordinatorTests {
    private let tiny = UITestBank.tiny

    private func environment(fetchDelay: Double = 0, store: (any RankingStore)? = nil, user: AuthUser? = nil,
                             player: RecordingPlayer = RecordingPlayer()) -> (AppEnvironment, FakeAnalytics) {
        let defaults = UserDefaults(suiteName: "PlayCoordinatorTests.\(UUID().uuidString)")!
        let bank = RemoteBank(questions: tiny, documentCount: tiny.count)
        let remote = FakeQuestionSource(count: .success(tiny.count),
                                        fetch: fetchDelay > 0 ? .delayed(bank, seconds: fetchDelay) : .success(bank))
        let analytics = FakeAnalytics()
        let env = AppEnvironment(
            questionBank: QuestionBank(remote: remote, cache: InMemoryQuestionCache(nil), bundled: { [] }),
            rankingStore: store, auth: FakeAuthService(user: user), analytics: analytics, defaults: defaults,
            player: { _ in player }, mail: FakeMailComposer(), connectivity: Connectivity(monitoring: false),
            firebaseAvailable: true, options: LaunchOptions(arguments: ["-feedbackMs", "0"])
        )
        analytics.apply(.accepted(Date()))
        return (env, analytics)
    }

    private func waitUntilPlaying(_ play: PlayCoordinator) async throws -> GameSession {
        for _ in 0..<200 {
            if case .playing(let session) = play.phase { return session }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw TimeoutError()
    }

    /// A double tap (or closing and reopening while the questions load) must start one game.
    @Test func playingTwiceWhileLoadingStartsOneGame() async throws {
        let (env, analytics) = environment(fetchDelay: 0.3)
        env.play.play(.arcade())
        env.play.play(.arcade())
        _ = try await waitUntilPlaying(env.play)
        try await Task.sleep(for: .milliseconds(500))
        #expect(analytics.events.filter { $0.name == "game_start" }.count == 1)
        env.play.close()
    }

    /// A slow save of a competitive game must not land on the report of the game after it.
    @Test func aSlowSaveDoesNotReachTheNextGamesReport() async throws {
        let store = FakeRankingStore(delay: 0.3)
        let user = AuthUser(uid: "me", displayName: "Yo", photoURL: nil, provider: .google)
        let (env, _) = environment(store: store, user: user)
        env.play.play(GameSetup(mode: .competitive, duration: .short, filter: .medium, category: nil))
        try await waitUntilPlaying(env.play).leave()
        env.play.finish(GameFixtures.report(rights: 3))
        #expect(env.play.submission == .saving)

        env.play.close()
        env.play.play(.arcade())
        _ = try await waitUntilPlaying(env.play)
        try await Task.sleep(for: .seconds(1.5)) // the old save finishes meanwhile
        #expect(env.play.submission == nil)
        env.play.close()
    }

    /// The audio is warmed up when the game starts, not at the first answer.
    @Test func startingAGamePreparesTheSound() async throws {
        let player = RecordingPlayer()
        let (env, _) = environment(player: player)
        env.play.play(.arcade())
        _ = try await waitUntilPlaying(env.play)
        #expect(player.calls.first == "prepare")
        env.play.close()
    }

    /// An impossible score is reported as such, without an endless "Reintentar".
    @Test func impossibleScoreEndsAsRejected() async throws {
        let user = AuthUser(uid: "me", displayName: "Yo", photoURL: nil, provider: .google)
        let (env, _) = environment(store: FakeRankingStore(), user: user)
        env.play.play(GameSetup(mode: .competitive, duration: .short, filter: .medium, category: nil))
        try await waitUntilPlaying(env.play).leave()
        let report = GameFixtures.report(rights: 3)
        env.play.finish(GameReport(
            points: 99, correct: 1, wrong: report.wrong, skipped: report.skipped, bestStreak: 1,
            breakdown: report.breakdown, rows: report.rows, finishReason: report.finishReason,
            duration: report.duration, filter: report.filter, category: report.category, celebration: report.celebration
        ))
        for _ in 0..<100 where env.play.submission == .saving { try await Task.sleep(for: .milliseconds(10)) }
        #expect(env.play.submission == .rejected)
        env.play.close()
    }
}
