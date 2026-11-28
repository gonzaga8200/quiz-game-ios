/// What a game is played with (the web's `useGameSetup`).
nonisolated enum GameMode: String, Sendable {
    case arcade, competitive
}

nonisolated struct GameSetup: Hashable, Sendable {
    let mode: GameMode
    let duration: GameDuration
    let filter: DifficultyFilter
    /// One category only: arcade from a category page, or chosen in competitive mode.
    let category: QuizCategory?

    /// Arcade is fixed: 60 s, random difficulty, optionally one category.
    static func arcade(category: QuizCategory? = nil) -> GameSetup {
        GameSetup(mode: .arcade, duration: Rules.arcadeDuration, filter: Rules.arcadeFilter, category: category)
    }
}
