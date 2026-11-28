/// Ranking boards: one per duration + difficulty filter + category choice. Port of `core/filters.ts`.
public struct Board: Hashable, Sendable {
    public let id: String
    public let duration: GameDuration
    public let filter: DifficultyFilter
    /// Absent on the boards of games that mix every category.
    public let category: QuizCategory?
}

/// `60_aleatorio` for games that mix every category, `60_aleatorio_ciencias` for one category.
public func boardId(_ duration: GameDuration, _ filter: DifficultyFilter, _ category: QuizCategory?) -> String {
    let base = "\(duration.rawValue)_\(filter.slug)"
    guard let category else { return base }
    return "\(base)_\(category.urlSlug)"
}

/// All 64 boards (2 durations x 4 filters x 8 category choices), in the web's display order.
public let allBoards: [Board] = GameDuration.allCases.flatMap { duration in
    DifficultyFilter.allCases.flatMap { filter in
        [Board(id: boardId(duration, filter, nil), duration: duration, filter: filter, category: nil)]
            + QuizCategory.allCases.map { category in
                Board(id: boardId(duration, filter, category), duration: duration, filter: filter, category: category)
            }
    }
}

/// Whether a finished game improves on the player's stored best for a board.
public func isPersonalBest(previousBest: Int?, points: Int) -> Bool {
    guard let previousBest else { return true }
    return points > previousBest
}
