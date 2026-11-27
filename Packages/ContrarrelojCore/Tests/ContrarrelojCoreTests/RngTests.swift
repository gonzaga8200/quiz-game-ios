import Testing
@testable import ContrarrelojCore

private struct RngFixture: Decodable {
    struct Case: Decodable {
        let seed: UInt32
        let values: [Double]
        let shuffled: [Int]
    }
    let cases: [Case]
}

@Test func mulberry32MatchesFixture() throws {
    let fixture = try Fixture.load("rng", as: RngFixture.self)
    #expect(fixture.cases.count == 4)
    for testCase in fixture.cases {
        let rng = mulberry32(seed: testCase.seed)
        let values = (0..<20).map { _ in rng() }
        #expect(values == testCase.values, "seed \(testCase.seed)")
    }
}

@Test func shuffledMatchesFixture() throws {
    let fixture = try Fixture.load("rng", as: RngFixture.self)
    for testCase in fixture.cases {
        let input = Array(0...9)
        #expect(shuffled(input, rng: mulberry32(seed: testCase.seed)) == testCase.shuffled, "seed \(testCase.seed)")
        #expect(input == Array(0...9))
    }
}

@Test func valuesStayInTheUnitInterval() {
    let rng = mulberry32(seed: 7)
    for _ in 0..<1_000 {
        let value = rng()
        #expect(value >= 0 && value < 1)
    }
}
