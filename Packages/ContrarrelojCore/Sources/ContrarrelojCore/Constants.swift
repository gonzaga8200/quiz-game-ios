/// Game constants: categories, difficulties and the scoring tables. Port of `core/constants.ts`.
/// Raw values are exactly the strings stored in Firestore and in the question files.

public enum Difficulty: String, CaseIterable, Codable, Sendable, Comparable {
    case veryEasy = "muy fácil"
    case easy = "fácil"
    case medium = "medio"
    case hard = "difícil"
    case veryHard = "muy difícil"

    /// Ordered from easiest to hardest.
    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

/// What the player picks in competitive mode ("Aleatorio" also drives arcade mode).
public enum DifficultyFilter: String, CaseIterable, Codable, Sendable {
    case random = "Aleatorio"
    case easy = "Fácil"
    case medium = "Medio"
    case hard = "Difícil"
}

/// Game length in seconds. Named `GameDuration` so it never shadows `Swift.Duration`.
public enum GameDuration: Int, CaseIterable, Codable, Sendable {
    case short = 60
    case long = 120

    public var milliseconds: Double { Double(rawValue) * 1000 }
}

public enum QuestionStatus: String, Codable, Sendable {
    case active
    case disabled
}

public enum Rules {
    public static let optionsPerQuestion = 4

    /// Random mode never serves more than this many questions in a row of the same difficulty.
    public static let maxSameInARow = 2

    /// No filter serves more than this many questions in a row of the same category (except a
    /// game limited to one category, where every question shares it).
    public static let maxSameCategoryInARow = 1

    /// Arcade mode is always 60 s with random difficulty.
    public static let arcadeDuration = GameDuration.short
    public static let arcadeFilter = DifficultyFilter.random

    public static let pointsByDifficulty: [Difficulty: Int] = [
        .veryEasy: 3, .easy: 5, .medium: 7, .hard: 10, .veryHard: 15,
    ]

    /// Points lost for a wrong answer, before the score floor is applied.
    public static let wrongPenaltyByDifficulty: [Difficulty: Int] = [
        .veryEasy: 2, .easy: 1, .medium: 0, .hard: 0, .veryHard: 0,
    ]

    /// Combo bonus keyed by the streak length that triggers it, awarded once per streak.
    public static let comboBonuses: [Int: Int] = [3: 2, 5: 4, 10: 8]

    public static let freeSkips = 2
    public static let paidSkipPenalty = 1

    /// Upper bound of points per correct answer, used to sanity-check submitted scores.
    public static let maxPointsPerCorrect = 17

    /// Number of entries shown per ranking board.
    public static let rankingSize = 50
}
