import Foundation
import Testing
@testable import Contrarreloj

private let player = RankingPlayer(uid: "ana", displayName: "Ana García", photoURL: "https://lh3.googleusercontent.com/a/x")

nonisolated private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var _now = Date(timeIntervalSince1970: 1_800_000_000)
    var now: Date { lock.withLock { _now } }
    func advance(_ seconds: TimeInterval) { lock.withLock { _now = _now.addingTimeInterval(seconds) } }
}

struct RankingServiceTests {
    private func service(_ store: FakeRankingStore, clock: Clock = Clock(),
                         sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) -> RankingService {
        RankingService(store: store, now: { clock.now }, sleep: sleep)
    }

    // MARK: toScoreSubmission

    @Test func submissionFromReportAndProfile() {
        let report = GameFixtures.report(rights: 5)
        #expect(toScoreSubmission(player: player, report: report) == ScoreSubmission(
            uid: "ana", displayName: "Ana García", photoURL: "https://lh3.googleusercontent.com/a/x",
            points: report.points, correct: 5, wrong: 0, skipped: 0, duration: .short, difficultyFilter: .medium, category: nil
        ))
    }

    @Test func categoryBoardWhenCategorySet() async throws {
        let limited = toScoreSubmission(player: player, report: GameFixtures.report(rights: 3, filter: .random, category: .historyAndGeography))
        #expect(limited.category == .historyAndGeography)
        let store = FakeRankingStore()
        _ = try await service(store).submit(player: player, report: GameFixtures.report(rights: 4, filter: .random, category: .historyAndGeography))
        #expect(store.saved.first?.board == "60_aleatorio_historia-y-geografia")
    }

    @Test func nameFallsBackToJugadorAndIsCut() {
        let report = GameFixtures.report(rights: 2)
        #expect(toScoreSubmission(player: RankingPlayer(uid: "ana", displayName: nil, photoURL: nil), report: report).displayName == "Jugador")
        #expect(toScoreSubmission(player: RankingPlayer(uid: "ana", displayName: "   ", photoURL: nil), report: report).displayName == "Jugador")
        let long = toScoreSubmission(player: RankingPlayer(uid: "ana", displayName: " " + String(repeating: "x", count: 80) + " ", photoURL: nil), report: report)
        #expect(long.displayName.count == 60)
    }

    @Test func httpPhotoBecomesNull() {
        let report = GameFixtures.report(rights: 2)
        #expect(toScoreSubmission(player: RankingPlayer(uid: "a", displayName: "A", photoURL: "http://insecure.example/a.png"), report: report).photoURL == nil)
        #expect(toScoreSubmission(player: RankingPlayer(uid: "a", displayName: "A", photoURL: "https://x.example/" + String(repeating: "a", count: 500)), report: report).photoURL == nil)
    }

    // MARK: submit

    @Test func firstScoreIsNewBest() async throws {
        let store = FakeRankingStore(best: nil, better: 4)
        let report = GameFixtures.report(rights: 6)
        let result = try await service(store).submit(player: player, report: report)
        #expect(result == .newBest(best: report.points, position: 5))
        #expect(store.saved.map(\.board) == ["60_medio"])
        #expect(store.saved.first?.entry.points == report.points)
        #expect(store.countBetterCalls.last == CountCall(board: "60_medio", points: report.points))
    }

    @Test func lowerPreviousBestIsReplaced() async throws {
        let store = FakeRankingStore(best: 10, better: 0)
        let result = try await service(store).submit(player: player, report: GameFixtures.report(rights: 6))
        #expect(result == .newBest(best: GameFixtures.report(rights: 6).points, position: 1))
        #expect(store.saved.count == 1)
    }

    @Test(arguments: [0, 500])
    func equalOrHigherPreviousBestIsKept(extra: Int) async throws {
        let report = GameFixtures.report(rights: 6)
        let store = FakeRankingStore(best: report.points + extra, better: 2)
        let result = try await service(store).submit(player: player, report: report)
        #expect(result == .kept(best: report.points + extra, position: 3))
        #expect(store.saved.isEmpty)
        #expect(store.countBetterCalls.last == CountCall(board: "60_medio", points: report.points + extra))
    }

    @Test func zeroPointsIsSkipped() async throws {
        let store = FakeRankingStore()
        let result = try await service(store).submit(player: player, report: GameFixtures.report(rights: 0))
        #expect(result == .skipped)
        #expect(store.bestCalls == 0)
        #expect(store.saved.isEmpty)
    }

    @Test func positionIsBetterCountPlusOne() async throws {
        let store = FakeRankingStore(best: nil, better: 0)
        let result = try await service(store).submit(player: player, report: GameFixtures.report(rights: 4, duration: .long, filter: .random))
        #expect(result == .newBest(best: GameFixtures.report(rights: 4, duration: .long, filter: .random).points, position: 1))
        #expect(store.saved.first?.board == "120_aleatorio")
    }

    @Test func storeErrorsReachTheCaller() async {
        let store = FakeRankingStore(failing: true)
        await #expect(throws: FakeRemoteError.self) {
            try await service(store).submit(player: player, report: GameFixtures.report(rights: 3))
        }
    }

    // MARK: top

    @Test func topIsCachedForSixtySeconds() async throws {
        let store = FakeRankingStore()
        let clock = Clock()
        let ranking = service(store, clock: clock)
        _ = try await ranking.top(board: "60_medio")
        clock.advance(59)
        _ = try await ranking.top(board: "60_medio")
        #expect(store.topCalls == 1)
        clock.advance(2)
        _ = try await ranking.top(board: "60_medio")
        #expect(store.topCalls == 2)
    }

    @Test func forceRefreshBypassesCache() async throws {
        let store = FakeRankingStore()
        let ranking = service(store)
        _ = try await ranking.top(board: "60_medio")
        _ = try await ranking.top(board: "60_medio", forceRefresh: true)
        #expect(store.topCalls == 2)
    }

    @Test func submittingInvalidatesThatBoardsCache() async throws {
        let store = FakeRankingStore(best: nil, better: 0)
        let ranking = service(store)
        _ = try await ranking.top(board: "60_medio")
        _ = try await ranking.submit(player: player, report: GameFixtures.report(rights: 3))
        _ = try await ranking.top(board: "60_medio")
        #expect(store.topCalls == 2)
    }

    @Test func rankingCallTimesOutAfterTenSeconds() async {
        let store = FakeRankingStore(hanging: true)
        let recorded = DurationLog()
        let ranking = service(store, sleep: { duration in recorded.append(duration) })
        await #expect(throws: TimeoutError.self) { try await ranking.top(board: "60_medio") }
        #expect(recorded.values == [.seconds(10)])
    }
}

nonisolated private final class DurationLog: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [Duration] = []
    var values: [Duration] { lock.withLock { _values } }
    func append(_ d: Duration) { lock.withLock { _values.append(d) } }
}
