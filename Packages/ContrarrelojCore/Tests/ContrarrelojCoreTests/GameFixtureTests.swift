import Foundation
import Testing
@testable import ContrarrelojCore

private struct GamesFixture: Decodable {
    struct Config: Decodable {
        let seed: UInt32
        let filter: DifficultyFilter
        let duration: GameDuration
        let category: QuizCategory?
        let seen: Bool
    }
    struct Snapshot: Decodable, Equatable {
        let status: String
        let currentId: String?
        let score, streak, bestStreak, correct, wrong, skipped, freeSkipsLeft, skipCost: Int
        let remainingMs: Double
        let finishReason: String?
    }
    struct Result: Decodable {
        let kind: String?
        let status: String?
        let result: ResultKind?
        let chosenIndex, correctIndex, points, bonus, penalty, streak, freeSkipsLeft: Int?
        let free: Bool?
    }
    struct Step: Decodable {
        let t: Double
        let action: String
        let index: Int?
        let result: Result?
        let snapshot: Snapshot
    }
    struct Game: Decodable {
        let config: Config
        let steps: [Step]
        let report: GameReport
        let shownIds: [String]
    }
    let games: [Game]
}

private extension GamesFixture.Result {
    var outcome: Outcome? {
        switch kind {
        case "answered":
            .answered(result: result!, chosenIndex: chosenIndex!, correctIndex: correctIndex!, points: points!,
                      bonus: bonus!, penalty: penalty!, streak: streak!)
        case "skipped": .skipped(free: free!, penalty: penalty!, freeSkipsLeft: freeSkipsLeft!)
        case "expired": .expired
        case "ignored": .ignored
        default: nil
        }
    }
}

private func snapshotFields(_ s: GameSnapshot) -> GamesFixture.Snapshot {
    .init(status: s.status.rawValue, currentId: s.current?.id, score: s.score, streak: s.streak,
          bestStreak: s.bestStreak, correct: s.correct, wrong: s.wrong, skipped: s.skipped,
          freeSkipsLeft: s.freeSkipsLeft, skipCost: s.skipCost, remainingMs: s.remainingMs,
          finishReason: s.finishReason?.rawValue)
}

@Test func gamesMatchFixture() throws {
    let sample = try QuestionsFixture.load()
    let fixture = try Fixture.load("games", as: GamesFixture.self)
    #expect(fixture.games.count == 12)

    for scripted in fixture.games {
        let config = scripted.config
        var now = 0.0
        let game = Game(GameConfig(
            questions: sample.questions, filter: config.filter, duration: config.duration,
            category: config.category, seen: config.seen ? sample.seen : nil,
            rng: mulberry32(seed: config.seed), now: { now }
        ))
        let label = "seed \(config.seed)"
        for (number, step) in scripted.steps.enumerated() {
            now = step.t
            switch step.action {
            case "start":
                game.start()
            case "answer":
                #expect(game.answer(step.index!) == step.result?.outcome, "\(label) step \(number)")
            case "skip":
                #expect(game.skip() == step.result?.outcome, "\(label) step \(number)")
            case "next":
                #expect(game.next().rawValue == step.result?.status, "\(label) step \(number)")
            case "tick":
                #expect(game.tick().rawValue == step.result?.status, "\(label) step \(number)")
            default:
                Issue.record("unknown action \(step.action)")
            }
            #expect(snapshotFields(game.snapshot()) == step.snapshot, "\(label) step \(number) \(step.action)")
        }
        #expect(game.report() == scripted.report, "\(label) report")
        #expect(game.shownIds() == scripted.shownIds, "\(label) shown ids")
    }
}
