/// Celebration tiers by points per minute, so 60 s and 120 s games compare. Port of `core/celebration.ts`.
public enum CelebrationTier: String, Codable, Sendable {
    case trophy, party, clap, thumbs, `try`
}

public struct Celebration: Codable, Equatable, Sendable {
    public let tier: CelebrationTier
    /// Emojis the UI shoots as confetti.
    public let emojis: [String]
    /// How many pieces to launch; scales with the result.
    public let particleCount: Int

    public init(tier: CelebrationTier, emojis: [String], particleCount: Int) {
        self.tier = tier
        self.emojis = emojis
        self.particleCount = particleCount
    }
}

private let tiers: [(minPointsPerMinute: Double, celebration: Celebration)] = [
    (150, Celebration(tier: .trophy, emojis: ["🏆", "🥇", "✨"], particleCount: 240)),
    (90, Celebration(tier: .party, emojis: ["🎉", "🥳", "✨"], particleCount: 170)),
    (45, Celebration(tier: .clap, emojis: ["👏", "🙌"], particleCount: 110)),
    (15, Celebration(tier: .thumbs, emojis: ["👍", "🙂"], particleCount: 60)),
    (0, Celebration(tier: .try, emojis: ["💪"], particleCount: 30)),
]

public func celebrationFor(points: Int, duration: GameDuration) -> Celebration {
    let perMinute = Double(points) / (Double(duration.rawValue) / 60)
    return (tiers.first { perMinute >= $0.minPointsPerMinute } ?? tiers[tiers.count - 1]).celebration
}
