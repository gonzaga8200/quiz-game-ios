import Foundation
import Testing
@testable import Contrarreloj

struct RankingPositionsTests {
    private func entry(_ points: Int) -> RankingEntry {
        RankingEntry(uid: "u\(points)", displayName: "J", photoURL: nil, points: points, correct: 10, wrong: 0, skipped: 0,
                     duration: .short, difficultyFilter: .random, category: nil, createdAt: Date())
    }

    @Test func tiesShareThePositionOfTheReport() {
        #expect(rankingPositions([entry(140), entry(98), entry(98), entry(70)]) == [1, 2, 2, 4])
        #expect(rankingPositions([]) == [])
        #expect(rankingPositions([entry(5), entry(5), entry(5)]) == [1, 1, 1])
    }
}
