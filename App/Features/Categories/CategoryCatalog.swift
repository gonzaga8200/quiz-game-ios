import Foundation

/// The counts and the showcase of every category, worked out once per bank (about 2,600
/// questions) and off the main thread, instead of on every redraw of the categories screens.
nonisolated struct CategoryCatalog: Sendable {
    static let showcaseSize = 20

    let counts: [QuizCategory: Int]
    private let showcases: [QuizCategory: [Question]]

    init(questions: [Question]) {
        counts = countActiveByCategory(questions)
        var showcases: [QuizCategory: [Question]] = [:]
        for category in QuizCategory.allCases {
            let picked = pickShowcase(questions, category: category, count: Self.showcaseSize)
            if !picked.isEmpty { showcases[category] = picked }
        }
        self.showcases = showcases
    }

    /// No active question at all (every source failed): the screens offer a retry.
    var isEmpty: Bool { counts.values.allSatisfy { $0 == 0 } }

    /// The same stable selection as the web's category page, easiest first.
    func showcase(for category: QuizCategory) -> [Question] {
        showcases[category] ?? []
    }
}
