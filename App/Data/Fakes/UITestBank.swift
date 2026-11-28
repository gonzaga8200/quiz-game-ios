import Foundation

/// Known data for UI tests. The right option of every question is literally "Correcta", so a test
/// can answer right or wrong without any hint in the production UI.
enum UITestBank {
    static let tiny: [Question] = {
        let categories: [QuizCategory] = [.science, .music, .sports, .science, .historyAndGeography, .artAndLiterature]
        return categories.enumerated().map { i, category in
            Question(
                id: "prueba-\(i + 1)", text: "¿Cuál es la respuesta correcta de la prueba \(i + 1)?",
                options: ["Correcta", "Falsa uno", "Falsa dos", "Falsa tres"], correctIndex: 0, category: category,
                difficulty: .medium, explanation: "La correcta se llama así para las pruebas.", source: nil,
                createdAt: "2026-11-27T00:00:00.000Z", status: .active
            )
        }
    }()

    static func ranking(_ mode: String?) -> any RankingStore {
        switch mode {
        case "failing": return FakeRankingStore(failing: true)
        case "seeded": return FakeRankingStore(best: nil, better: 2, boards: seededBoards)
        default: return FakeRankingStore()
        }
    }

    static var seededBoards: [String: [RankingEntry]] {
        func entry(_ uid: String, _ name: String, _ points: Int) -> RankingEntry {
            RankingEntry(uid: uid, displayName: name, photoURL: nil, points: points, correct: points / 7, wrong: 1,
                         skipped: 0, duration: .short, difficultyFilter: .random, category: nil,
                         createdAt: Date(timeIntervalSince1970: 1_800_000_000))
        }
        return [
            "60_aleatorio": [entry("u1", "Ana", 140), entry("u2", "Luis", 98), entry("u3", "Marta", 98), entry("me", "Yo", 70)],
            "120_aleatorio": [entry("u4", "Pedro", 210)],
        ]
    }
}
