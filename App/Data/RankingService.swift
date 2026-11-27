import Foundation

/// The few Firestore operations the ranking needs (the real one is FirestoreRankingStore).
nonisolated protocol RankingStore: Sendable {
    /// The player's stored best on a board, or nil if they have none.
    func getBestPoints(board: String, uid: String) async throws -> Int?
    func saveEntry(board: String, entry: ScoreSubmission) async throws
    /// How many players on the board have strictly more points.
    func countBetter(board: String, points: Int) async throws -> Int
    func topEntries(board: String) async throws -> [RankingEntry]
    /// Deletes the player's entry on each board (account deletion). Missing entries are fine.
    func deleteEntries(uid: String, boards: [String]) async throws
}

nonisolated struct RankingPlayer: Sendable, Equatable {
    let uid: String
    let displayName: String?
    let photoURL: String?
}

nonisolated enum SubmitResult: Equatable, Sendable {
    /// Zero points: nothing worth ranking.
    case skipped
    /// The score beat (or created) the player's best on this board.
    case newBest(best: Int, position: Int)
    /// The player already has an equal or better score; it was left untouched.
    case kept(best: Int, position: Int)
}

/// The document to store for a finished game, with the profile data cleaned up like the web's
/// `toScoreSubmission`: name trimmed and cut to 60, "Jugador" when empty; only https photos.
nonisolated func toScoreSubmission(player: RankingPlayer, report: GameReport) -> ScoreSubmission {
    let trimmed = (player.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let cut = String(decoding: Array(trimmed.utf16.prefix(60)), as: UTF16.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let photo = player.photoURL.flatMap { $0.hasPrefix("https://") && $0.utf16.count <= 500 ? $0 : nil }
    return ScoreSubmission(
        uid: player.uid, displayName: cut.isEmpty ? "Jugador" : cut, photoURL: photo, points: report.points,
        correct: report.correct, wrong: report.wrong, skipped: report.skipped, duration: report.duration,
        difficultyFilter: report.filter, category: report.category
    )
}

/// Saves competitive games (one entry per player per board, only when it improves) and reads the
/// boards, with a one-minute cache per board so switching filters does not re-read 50 documents.
actor RankingService {
    private let store: any RankingStore
    private let now: @Sendable () -> Date
    private let cacheTTL: TimeInterval
    private let timeout: Duration
    private let sleep: Sleeper
    private var cache: [String: (at: Date, entries: [RankingEntry])] = [:]

    init(
        store: any RankingStore,
        now: @escaping @Sendable () -> Date = { Date() },
        cacheTTL: TimeInterval = 60,
        timeout: Duration = .seconds(10),
        sleep: @escaping Sleeper = realSleeper
    ) {
        self.store = store
        self.now = now
        self.cacheTTL = cacheTTL
        self.timeout = timeout
        self.sleep = sleep
    }

    func submit(player: RankingPlayer, report: GameReport) async throws -> SubmitResult {
        guard report.points > 0 else { return .skipped }
        let board = boardId(report.duration, report.filter, report.category)
        let store = store

        let previous = try await timed { try await store.getBestPoints(board: board, uid: player.uid) }
        if let previous, !isPersonalBest(previousBest: previous, points: report.points) {
            let better = try await timed { try await store.countBetter(board: board, points: previous) }
            return .kept(best: previous, position: better + 1)
        }

        let entry = toScoreSubmission(player: player, report: report)
        try await timed { try await store.saveEntry(board: board, entry: entry) }
        cache[board] = nil
        let better = try await timed { try await store.countBetter(board: board, points: report.points) }
        return .newBest(best: report.points, position: better + 1)
    }

    func top(board: String, forceRefresh: Bool = false) async throws -> [RankingEntry] {
        if !forceRefresh, let hit = cache[board], now().timeIntervalSince(hit.at) < cacheTTL {
            return hit.entries
        }
        let store = store
        let entries = try await timed { try await store.topEntries(board: board) }
        cache[board] = (now(), entries)
        return entries
    }

    private func timed<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withTimeout(timeout, sleep: sleep, operation)
    }
}
