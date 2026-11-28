import Foundation

nonisolated struct CountCall: Equatable, Sendable {
    let board: String
    let points: Int
}

nonisolated struct SavedEntry: Equatable, Sendable {
    let board: String
    let entry: ScoreSubmission
}

/// A ranking store for previews, tests and UI tests.
nonisolated final class FakeRankingStore: RankingStore, @unchecked Sendable {
    private let lock = NSLock()
    private let best: Int?
    private let better: Int
    private let failing: Bool
    private let hanging: Bool
    private let delay: Double
    private var boards: [String: [RankingEntry]]
    private var _saved: [SavedEntry] = []
    private var _countBetterCalls: [CountCall] = []
    private var _bestCalls = 0
    private var _topCalls = 0
    private var _deleted: [(uid: String, boards: [String])] = []

    init(best: Int? = nil, better: Int = 0, failing: Bool = false, hanging: Bool = false, delay: Double = 0,
         boards: [String: [RankingEntry]] = [:]) {
        self.best = best
        self.better = better
        self.failing = failing
        self.hanging = hanging
        self.delay = delay
        self.boards = boards
    }

    var saved: [SavedEntry] { lock.withLock { _saved } }
    var countBetterCalls: [CountCall] { lock.withLock { _countBetterCalls } }
    var bestCalls: Int { lock.withLock { _bestCalls } }
    var topCalls: Int { lock.withLock { _topCalls } }
    var deletedBoards: [String] { lock.withLock { _deleted.flatMap(\.boards) } }

    private func gate() async throws {
        if hanging { try await Task.sleep(for: .seconds(3_600)) }
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        if failing { throw FakeRemoteError.offline }
    }

    func getBestPoints(board: String, uid: String) async throws -> Int? {
        lock.withLock { _bestCalls += 1 }
        try await gate()
        return best
    }

    func saveEntry(board: String, entry: ScoreSubmission) async throws {
        try await gate()
        lock.withLock { _saved.append(SavedEntry(board: board, entry: entry)) }
    }

    func countBetter(board: String, points: Int) async throws -> Int {
        lock.withLock { _countBetterCalls.append(CountCall(board: board, points: points)) }
        try await gate()
        return better
    }

    func topEntries(board: String) async throws -> [RankingEntry] {
        lock.withLock { _topCalls += 1 }
        try await gate()
        return lock.withLock { boards[board] ?? [] }
    }

    func deleteEntries(uid: String, boards: [String]) async throws {
        try await gate()
        lock.withLock {
            _deleted.append((uid, boards))
            for board in boards { self.boards[board]?.removeAll { $0.uid == uid } }
        }
    }
}
