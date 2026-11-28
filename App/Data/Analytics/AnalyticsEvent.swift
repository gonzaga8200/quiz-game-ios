import Foundation

nonisolated enum AnalyticsValue: Equatable, Sendable {
    case string(String)
    case int(Int)

    var object: NSObject {
        switch self {
        case .string(let value): value as NSString
        case .int(let value): NSNumber(value: value)
        }
    }
}

/// Every event the app sends: the web's (`screen_view` for its `page_view`, `login_*`, `share`)
/// plus the app's own. Parameters never carry personal data.
nonisolated enum AnalyticsEvent: Equatable, Sendable {
    case screenView(String)
    case loginClick(AuthProvider)
    case loginSuccess(AuthProvider)
    case loginError(AuthProvider, code: String)
    case share(method: String, mode: GameMode)
    case gameStart(GameSetup)
    case gameEnd(GameSetup, GameReport)
    case questionReport(QuizCategory, Difficulty)
    case accountDeleted(AuthProvider)

    var name: String {
        switch self {
        case .screenView: "screen_view"
        case .loginClick: "login_click"
        case .loginSuccess: "login_success"
        case .loginError: "login_error"
        case .share: "share"
        case .gameStart: "game_start"
        case .gameEnd: "game_end"
        case .questionReport: "question_report"
        case .accountDeleted: "account_deleted"
        }
    }

    var parameters: [String: AnalyticsValue] {
        switch self {
        case .screenView(let screen):
            return ["screen_name": .string(screen), "screen_class": .string(screen)]
        case .loginClick(let provider), .loginSuccess(let provider), .accountDeleted(let provider):
            return ["method": .string(provider.rawValue)]
        case .loginError(let provider, let code):
            return ["method": .string(provider.rawValue), "error_code": .string(code)]
        case .share(let method, let mode):
            return ["method": .string(method), "content_type": .string("game_result"), "mode": .string(mode.rawValue)]
        case .gameStart(let setup):
            return Self.setup(setup)
        case .gameEnd(let setup, let report):
            return Self.setup(setup).merging([
                "points": .int(report.points), "correct": .int(report.correct), "wrong": .int(report.wrong),
                "skipped": .int(report.skipped), "best_streak": .int(report.bestStreak),
                "finish_reason": .string(report.finishReason.rawValue),
            ]) { $1 }
        case .questionReport(let category, let difficulty):
            return ["category": .string(category.urlSlug), "difficulty": .string(difficulty.analyticsSlug)]
        }
    }

    private static func setup(_ setup: GameSetup) -> [String: AnalyticsValue] {
        [
            "mode": .string(setup.mode.rawValue),
            "duration": .int(setup.duration.rawValue),
            "difficulty": .string(setup.filter.slug),
            "category": .string(setup.category?.urlSlug ?? "all"),
        ]
    }
}

extension Difficulty {
    /// ASCII value for analytics ("muy-facil"...).
    nonisolated var analyticsSlug: String {
        switch self {
        case .veryEasy: "muy-facil"
        case .easy: "facil"
        case .medium: "medio"
        case .hard: "dificil"
        case .veryHard: "muy-dificil"
        }
    }
}
