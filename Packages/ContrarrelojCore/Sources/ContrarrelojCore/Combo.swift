/// Port of `core/combo.ts`.
public struct ComboMilestone: Equatable, Sendable {
    /// Streak length that triggers the bonus.
    public let at: Int
    public let bonus: Int

    public init(at: Int, bonus: Int) {
        self.at = at
        self.bonus = bonus
    }
}

private let milestones: [ComboMilestone] = Rules.comboBonuses
    .map { ComboMilestone(at: $0.key, bonus: $0.value) }
    .sorted { $0.at < $1.at }

/// The next bonus the player can still earn, or nil once the last one is behind them.
public func nextComboMilestone(streak: Int) -> ComboMilestone? {
    milestones.first { $0.at > streak }
}
