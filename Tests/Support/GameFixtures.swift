import Foundation
@testable import Contrarreloj

/// Small question banks and finished games for app tests (the web's tests/core/helpers.ts).
enum GameFixtures {
    static func bank(_ difficulty: Difficulty = .medium, count: Int, category: QuizCategory? = nil) -> [Question] {
        (0..<count).map { i in
            Question(
                id: "pregunta-\(difficulty.rawValue.replacingOccurrences(of: " ", with: "-").folding(options: .diacriticInsensitive, locale: nil))-\(i)",
                text: "¿Pregunta de prueba número \(i)?", options: ["Uno", "Dos", "Tres", "Cuatro"],
                correctIndex: i % 4, category: category ?? QuizCategory.allCases[i % QuizCategory.allCases.count],
                difficulty: difficulty, explanation: "Explicación de la pregunta \(i).", source: nil,
                createdAt: "2026-11-16T00:00:00.000Z", status: .active
            )
        }
    }

    /// Plays `rights` correct answers and returns the report. The questions have the first difficulty
    /// the filter lets through (medio = 7 points each, plus combo bonuses).
    static func report(
        rights: Int, duration: GameDuration = .short, filter: DifficultyFilter = .medium, category: QuizCategory? = nil
    ) -> GameReport {
        var now = 0.0
        let game = Game(GameConfig(
            questions: bank(filter.difficulties.first!, count: max(rights, 1), category: category), filter: filter, duration: duration,
            category: category, seen: nil, rng: mulberry32(seed: 1), now: { now }
        ))
        game.start()
        for _ in 0..<rights {
            _ = game.answer(game.snapshot().current!.correctIndex)
            _ = game.next()
        }
        now += 1_000_000
        game.tick()
        return game.report()!
    }
}
