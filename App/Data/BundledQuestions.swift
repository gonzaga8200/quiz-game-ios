import Foundation
import OSLog

/// The questions shipped inside the app (`Resources/questions.json`, synced from the web's
/// `data/questions` by Tools/sync-questions.sh). They keep the game playable offline and without
/// Firebase. Decoded once, lazily, off the main thread by whoever asks first.
nonisolated enum BundledQuestions {
    static let all: [Question] = load()

    private static func load() -> [Question] {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            Logger(subsystem: "com.contrarrelojquiz.app", category: "questions").error("bundled questions missing")
            return []
        }
        do {
            return try JSONDecoder().decode([Question].self, from: data)
        } catch {
            Logger(subsystem: "com.contrarrelojquiz.app", category: "questions").error("bundled questions invalid: \(error)")
            return []
        }
    }
}
