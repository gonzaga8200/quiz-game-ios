/// Port of `core/filters.ts` (difficulty filters; boards live in Boards.swift).
extension DifficultyFilter {
    /// Which question difficulties the filter lets through.
    public var difficulties: [Difficulty] {
        switch self {
        case .random: Difficulty.allCases
        case .easy: [.veryEasy, .easy]
        case .medium: [.medium]
        case .hard: [.hard, .veryHard]
        }
    }

    /// ASCII slug used in ranking board ids (document paths avoid accents).
    public var slug: String {
        switch self {
        case .random: "aleatorio"
        case .easy: "facil"
        case .medium: "medio"
        case .hard: "dificil"
        }
    }
}
