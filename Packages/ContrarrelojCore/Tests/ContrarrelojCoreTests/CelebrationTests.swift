import Testing
@testable import ContrarrelojCore

private struct CelebrationFixture: Decodable {
    struct Case: Decodable {
        let points: Int
        let duration: GameDuration
        let tier: CelebrationTier
        let emojis: [String]
        let particleCount: Int
    }
    let cases: [Case]
}

private struct ComboFixture: Decodable {
    struct Milestone: Decodable { let at: Int; let bonus: Int }
    struct Case: Decodable { let streak: Int; let milestone: Milestone? }
    let cases: [Case]
}

@Test func celebrationMatchesFixture() throws {
    let fixture = try Fixture.load("celebration", as: CelebrationFixture.self)
    #expect(fixture.cases.count == 116)
    for c in fixture.cases {
        #expect(
            celebrationFor(points: c.points, duration: c.duration)
                == Celebration(tier: c.tier, emojis: c.emojis, particleCount: c.particleCount),
            "\(c.points) in \(c.duration.rawValue) s"
        )
    }
}

@Test func comboMatchesFixture() throws {
    let fixture = try Fixture.load("combo", as: ComboFixture.self)
    for c in fixture.cases {
        let expected = c.milestone.map { ComboMilestone(at: $0.at, bonus: $0.bonus) }
        #expect(nextComboMilestone(streak: c.streak) == expected, "streak \(c.streak)")
    }
}
