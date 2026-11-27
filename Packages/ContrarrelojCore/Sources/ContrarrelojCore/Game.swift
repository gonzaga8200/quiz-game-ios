/// The game state machine. Port of `core/game.ts`: framework-agnostic and deterministic, with all
/// randomness and time coming from the injected `rng` and `now`.
///
///   ready --start()--> question --answer()/skip()--> feedback --next()--> question ...
///   any state --(timer reaches 0)--> finished   (the question in flight is discarded)
///   next() with no questions left --> finished (exhausted)
///
/// The clock keeps running during `feedback`. The UI calls `tick()` regularly so the game ends on
/// time even if the player does nothing.

public enum GameStatus: String, Sendable {
    case ready, question, feedback, finished
}

public enum FinishReason: String, Codable, Sendable {
    case time, exhausted
}

public enum ResultKind: String, Codable, Sendable {
    case correct, wrong, skipped
}

public struct GameConfig {
    public let questions: [Question]
    public let filter: DifficultyFilter
    public let duration: GameDuration
    /// Only serve questions of this category. Nil = every category.
    public let category: QuizCategory?
    /// How many times this device has already shown each question; the least shown come first.
    public let seen: [String: Int]?
    public let rng: Rng
    /// Monotonic clock in milliseconds.
    public let now: () -> Double

    public init(
        questions: [Question], filter: DifficultyFilter, duration: GameDuration, category: QuizCategory?,
        seen: [String: Int]?, rng: @escaping Rng, now: @escaping () -> Double
    ) {
        self.questions = questions
        self.filter = filter
        self.duration = duration
        self.category = category
        self.seen = seen
        self.rng = rng
        self.now = now
    }
}

/// One question the player actually handled. Discarded questions never appear.
public struct QuestionResult: Equatable, Sendable {
    public let question: PlayableQuestion
    public let result: ResultKind
    public let chosenIndex: Int?
    public let timeMs: Double
    /// Base points earned (correct answers only).
    public let points: Int
    /// Combo bonus earned by this answer.
    public let bonus: Int
    /// Points actually deducted, after the score floor.
    public let penalty: Int
    public let streakAfter: Int
}

public enum Outcome: Equatable, Sendable {
    case answered(result: ResultKind, chosenIndex: Int, correctIndex: Int, points: Int, bonus: Int, penalty: Int, streak: Int)
    case skipped(free: Bool, penalty: Int, freeSkipsLeft: Int)
    /// The timer ran out first: the question in flight was discarded and the game is over.
    case expired
    /// The call does not apply in the current state (double tap, bad index...).
    case ignored
}

public struct GameSnapshot: Equatable, Sendable {
    public let status: GameStatus
    public let current: PlayableQuestion?
    public let score: Int
    public let streak: Int
    public let bestStreak: Int
    public let correct: Int
    public let wrong: Int
    public let skipped: Int
    public let freeSkipsLeft: Int
    /// Points the next skip would cost: 0 while free skips remain.
    public let skipCost: Int
    public let remainingMs: Double
    public let finishReason: FinishReason?
}

public final class Game {
    private enum Phase {
        case ready
        case question(PlayableQuestion, presentedAt: Double)
        case feedback
        case finished(FinishReason)

        var status: GameStatus {
            switch self {
            case .ready: .ready
            case .question: .question
            case .feedback: .feedback
            case .finished: .finished
            }
        }
    }

    private let config: GameConfig
    private let durationMs: Double
    private let queue: [PlayableQuestion]
    private var resultsLog: [QuestionResult] = []
    private var phase: Phase = .ready
    private var startedAt = 0.0
    private var nextIndex = 0
    private var score = 0
    private var streak = 0
    private var bestStreak = 0
    private var freeSkipsLeft = Rules.freeSkips

    public init(_ config: GameConfig) {
        self.config = config
        durationMs = config.duration.milliseconds
        queue = buildQueue(config.questions, filter: config.filter, rng: config.rng,
                           category: config.category, seen: config.seen)
    }

    /// Starts the clock and shows the first question. Does nothing if already started.
    public func start() {
        guard case .ready = phase else { return }
        startedAt = config.now()
        present()
    }

    /// Ends the game if time is up. Returns the (possibly new) status.
    @discardableResult
    public func tick() -> GameStatus {
        expireIfTimeUp()
        return phase.status
    }

    public func answer(_ chosenIndex: Int) -> Outcome {
        guard case .question(let question, let presentedAt) = phase else { return .ignored }
        if expireIfTimeUp() { return .expired }
        guard chosenIndex >= 0, chosenIndex < question.options.count else { return .ignored }

        let correct = chosenIndex == question.correctIndex
        var points = 0
        var bonus = 0
        var penalty = 0
        if correct {
            streak += 1
            bestStreak = max(bestStreak, streak)
            points = Rules.pointsByDifficulty[question.difficulty] ?? 0
            bonus = Rules.comboBonuses[streak] ?? 0
            score += points + bonus
        } else {
            streak = 0
            penalty = deduct(Rules.wrongPenaltyByDifficulty[question.difficulty] ?? 0)
        }

        let result: ResultKind = correct ? .correct : .wrong
        record(question, presentedAt: presentedAt, result: result, chosenIndex: chosenIndex,
               points: points, bonus: bonus, penalty: penalty)
        return .answered(result: result, chosenIndex: chosenIndex, correctIndex: question.correctIndex,
                         points: points, bonus: bonus, penalty: penalty, streak: streak)
    }

    /// Skips the current question. The combo is kept. Costs points once free skips run out.
    public func skip() -> Outcome {
        guard case .question(let question, let presentedAt) = phase else { return .ignored }
        if expireIfTimeUp() { return .expired }

        let free = freeSkipsLeft > 0
        if free { freeSkipsLeft -= 1 }
        let penalty = deduct(free ? 0 : Rules.paidSkipPenalty)
        record(question, presentedAt: presentedAt, result: .skipped, chosenIndex: nil, points: 0, bonus: 0, penalty: penalty)
        return .skipped(free: free, penalty: penalty, freeSkipsLeft: freeSkipsLeft)
    }

    /// Moves from `feedback` to the next question (or ends the game).
    @discardableResult
    public func next() -> GameStatus {
        if case .feedback = phase, !expireIfTimeUp() { present() }
        return phase.status
    }

    public func remainingMs() -> Double {
        if case .ready = phase { return durationMs }
        return max(0, durationMs - (config.now() - startedAt))
    }

    /// Ids of the questions presented so far, in order, including the one on screen.
    public func shownIds() -> [String] {
        queue.prefix(nextIndex).map(\.id)
    }

    /// Handled questions in order.
    public func results() -> [QuestionResult] {
        resultsLog
    }

    /// The end-of-game report, or nil while the game is still running.
    public func report() -> GameReport? {
        guard case .finished(let reason) = phase else { return nil }
        return buildReport(ReportInput(
            results: resultsLog, bestStreak: bestStreak, finishReason: reason,
            duration: config.duration, filter: config.filter, category: config.category
        ))
    }

    public func snapshot() -> GameSnapshot {
        let current: PlayableQuestion?
        if case .question(let question, _) = phase { current = question } else { current = nil }
        let finishReason: FinishReason?
        if case .finished(let reason) = phase { finishReason = reason } else { finishReason = nil }
        return GameSnapshot(
            status: phase.status,
            current: current,
            score: score,
            streak: streak,
            bestStreak: bestStreak,
            correct: resultsLog.filter { $0.result == .correct }.count,
            wrong: resultsLog.filter { $0.result == .wrong }.count,
            skipped: resultsLog.filter { $0.result == .skipped }.count,
            freeSkipsLeft: freeSkipsLeft,
            skipCost: freeSkipsLeft > 0 ? 0 : Rules.paidSkipPenalty,
            remainingMs: remainingMs(),
            finishReason: finishReason
        )
    }

    // MARK: Private

    private func present() {
        guard nextIndex < queue.count else {
            phase = .finished(.exhausted)
            return
        }
        let question = queue[nextIndex]
        nextIndex += 1
        phase = .question(question, presentedAt: config.now())
    }

    /// Finishes the game when the clock has run out. Returns true if it just did.
    @discardableResult
    private func expireIfTimeUp() -> Bool {
        switch phase {
        case .ready, .finished: return false
        case .question, .feedback:
            guard remainingMs() <= 0 else { return false }
            phase = .finished(.time)
            return true
        }
    }

    /// Deducts up to `requested` points but never takes the score below zero.
    private func deduct(_ requested: Int) -> Int {
        let applied = min(requested, score)
        score -= applied
        return applied
    }

    private func record(
        _ question: PlayableQuestion, presentedAt: Double, result: ResultKind, chosenIndex: Int?,
        points: Int, bonus: Int, penalty: Int
    ) {
        resultsLog.append(QuestionResult(
            question: question, result: result, chosenIndex: chosenIndex, timeMs: config.now() - presentedAt,
            points: points, bonus: bonus, penalty: penalty, streakAfter: streak
        ))
        phase = .feedback
    }
}
