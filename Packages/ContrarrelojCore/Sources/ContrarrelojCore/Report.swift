/// The end-of-game report. Port of `core/report.ts`: the score is derived from the per-question
/// results, so the breakdown always adds up to the total.

public struct ReportRow: Codable, Equatable, Sendable {
    public let id: String
    public let text: String
    public let category: QuizCategory
    public let difficulty: Difficulty
    public let timeMs: Double
    public let result: ResultKind
    /// The option the player picked; nil when skipped.
    public let chosenAnswer: String?
    public let correctAnswer: String
    public let explanation: String
    /// Net points this question changed the score by (base + bonus - penalty).
    public let net: Int
}

public struct ComboBonusLine: Codable, Equatable, Sendable {
    /// Streak length that triggered the bonus (3, 5 or 10).
    public let streak: Int
    /// How many times it was earned during the game.
    public let count: Int
    public let points: Int
}

public struct ReportBreakdown: Codable, Equatable, Sendable {
    public let correctPoints: Int
    public let comboBonuses: [ComboBonusLine]
    public let comboBonusTotal: Int
    public let wrongPenalty: Int
    public let skipPenalty: Int
    public let penaltyTotal: Int
}

public struct GameReport: Codable, Equatable, Sendable {
    /// Final score: correctPoints + comboBonusTotal - penaltyTotal.
    public let points: Int
    public let correct: Int
    public let wrong: Int
    public let skipped: Int
    public let bestStreak: Int
    public let breakdown: ReportBreakdown
    public let rows: [ReportRow]
    public let finishReason: FinishReason
    public let duration: GameDuration
    public let filter: DifficultyFilter
    /// Set when the game was limited to one category.
    public let category: QuizCategory?
    public let celebration: Celebration
}

public struct ReportInput {
    public let results: [QuestionResult]
    public let bestStreak: Int
    public let finishReason: FinishReason
    public let duration: GameDuration
    public let filter: DifficultyFilter
    public let category: QuizCategory?

    public init(
        results: [QuestionResult], bestStreak: Int, finishReason: FinishReason, duration: GameDuration,
        filter: DifficultyFilter, category: QuizCategory?
    ) {
        self.results = results
        self.bestStreak = bestStreak
        self.finishReason = finishReason
        self.duration = duration
        self.filter = filter
        self.category = category
    }
}

private func row(_ entry: QuestionResult) -> ReportRow {
    let q = entry.question
    return ReportRow(
        id: q.id, text: q.text, category: q.category, difficulty: q.difficulty, timeMs: entry.timeMs,
        result: entry.result, chosenAnswer: entry.chosenIndex.map { q.options[$0] },
        correctAnswer: q.options[q.correctIndex], explanation: q.explanation,
        net: entry.points + entry.bonus - entry.penalty
    )
}

/// Groups combo bonuses by the streak length that triggered them, ascending.
private func bonusLines(_ results: [QuestionResult]) -> [ComboBonusLine] {
    var byStreak: [Int: ComboBonusLine] = [:]
    for entry in results where entry.bonus != 0 {
        let previous = byStreak[entry.streakAfter]
        byStreak[entry.streakAfter] = ComboBonusLine(
            streak: entry.streakAfter,
            count: (previous?.count ?? 0) + 1,
            points: (previous?.points ?? 0) + entry.bonus
        )
    }
    return byStreak.values.sorted { $0.streak < $1.streak }
}

public func buildReport(_ input: ReportInput) -> GameReport {
    let results = input.results
    func count(_ kind: ResultKind) -> Int { results.filter { $0.result == kind }.count }
    func penaltyOf(_ kind: ResultKind) -> Int { results.filter { $0.result == kind }.reduce(0) { $0 + $1.penalty } }

    let correctPoints = results.reduce(0) { $0 + $1.points }
    let comboBonuses = bonusLines(results)
    let comboBonusTotal = comboBonuses.reduce(0) { $0 + $1.points }
    let wrongPenalty = penaltyOf(.wrong)
    let skipPenalty = penaltyOf(.skipped)
    let penaltyTotal = wrongPenalty + skipPenalty
    let points = correctPoints + comboBonusTotal - penaltyTotal

    return GameReport(
        points: points,
        correct: count(.correct),
        wrong: count(.wrong),
        skipped: count(.skipped),
        bestStreak: input.bestStreak,
        breakdown: ReportBreakdown(
            correctPoints: correctPoints, comboBonuses: comboBonuses, comboBonusTotal: comboBonusTotal,
            wrongPenalty: wrongPenalty, skipPenalty: skipPenalty, penaltyTotal: penaltyTotal
        ),
        rows: results.map(row),
        finishReason: input.finishReason,
        duration: input.duration,
        filter: input.filter,
        category: input.category,
        celebration: celebrationFor(points: points, duration: input.duration)
    )
}
