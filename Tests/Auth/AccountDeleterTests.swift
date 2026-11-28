import Foundation
import Testing
@testable import Contrarreloj

/// A ranking store that writes into the same log as the fake auth service, to check the order.
nonisolated private final class LoggingRankingStore: RankingStore, @unchecked Sendable {
    let log: EventLog
    let failDelete: Bool
    let stallDelete: Bool
    private let lock = NSLock()
    private var _boards: [String] = []
    var boards: [String] { lock.withLock { _boards } }

    init(log: EventLog, failDelete: Bool = false, stallDelete: Bool = false) {
        self.log = log
        self.failDelete = failDelete
        self.stallDelete = stallDelete
    }

    func getBestPoints(board: String, uid: String) async throws -> Int? { nil }
    func saveEntry(board: String, entry: ScoreSubmission) async throws {}
    func countBetter(board: String, points: Int) async throws -> Int { 0 }
    func topEntries(board: String) async throws -> [RankingEntry] { [] }
    func deleteEntries(uid: String, boards: [String]) async throws {
        log.append("deleteEntries:\(uid)")
        if stallDelete { await uncancellableWait(seconds: 2) }
        if failDelete { throw FakeRemoteError.offline }
        lock.withLock { _boards = boards }
    }
}

struct AccountDeleterTests {
    private func setUp(provider: AuthProvider = .google, failDelete: Bool = false)
        -> (FakeAuthService, LoggingRankingStore, EventLog) {
        let log = EventLog()
        let auth = FakeAuthService(log: log)
        auth.user = AuthUser(uid: "ana", displayName: "Ana", photoURL: nil, provider: provider)
        return (auth, LoggingRankingStore(log: log, failDelete: failDelete), log)
    }

    /// Offline, Firestore queues the batch and never answers: give up after 10 s and keep the account.
    @Test func deletionGivesUpWhenTheServerNeverAnswers() async throws {
        let log = EventLog()
        let auth = FakeAuthService(log: log)
        auth.user = AuthUser(uid: "ana", displayName: "Ana", photoURL: nil, provider: .google)
        let ranking = LoggingRankingStore(log: log, stallDelete: true)
        let start = ContinuousClock.now
        await #expect(throws: TimeoutError.self) {
            _ = try await AccountDeleter(auth: auth, ranking: ranking, timeout: .seconds(10), sleep: { _ in }).delete()
        }
        #expect(ContinuousClock.now - start < .seconds(1))
        #expect(!log.events.contains("deleteUser"))
        #expect(auth.user != nil)
    }

    @Test func deletesEntriesBeforeUser() async throws {
        let (auth, ranking, log) = setUp(provider: .google)
        _ = try await AccountDeleter(auth: auth, ranking: ranking).delete()
        #expect(log.events == ["reauthenticate", "deleteEntries:ana", "disconnectGoogle", "deleteUser", "signOut"])
        #expect(ranking.boards.count == 64)
        #expect(Set(ranking.boards) == Set(allBoards.map(\.id)))
        #expect(auth.user == nil)
    }

    @Test func entriesFailureKeepsTheAccount() async {
        let (auth, ranking, log) = setUp(failDelete: true)
        await #expect(throws: FakeRemoteError.self) { _ = try await AccountDeleter(auth: auth, ranking: ranking).delete() }
        #expect(!log.events.contains("deleteUser"))
        #expect(auth.user != nil)
    }

    @Test func appleRevokeFailureDoesNotStopDeletion() async throws {
        let (auth, ranking, log) = setUp(provider: .apple)
        auth.revokeFails = true
        _ = try await AccountDeleter(auth: auth, ranking: ranking).delete()
        #expect(log.events == ["reauthenticate", "deleteEntries:ana", "revokeAppleToken", "deleteUser", "signOut"])
    }

    @Test func reauthCancelledAbortsEverything() async {
        let (auth, ranking, log) = setUp()
        auth.reauthFails = true
        await #expect(throws: (any Error).self) { _ = try await AccountDeleter(auth: auth, ranking: ranking).delete() }
        #expect(log.events == ["reauthenticate"])
    }

    @Test func returnsTheProviderForAnalytics() async throws {
        let (auth, ranking, _) = setUp(provider: .apple)
        #expect(try await AccountDeleter(auth: auth, ranking: ranking).delete() == .apple)
    }

    @Test func signedOutPlayersCannotDelete() async {
        let (auth, ranking, log) = setUp()
        auth.user = nil
        await #expect(throws: AccountDeletionError.notSignedIn) { _ = try await AccountDeleter(auth: auth, ranking: ranking).delete() }
        #expect(log.events.isEmpty)
    }
}
