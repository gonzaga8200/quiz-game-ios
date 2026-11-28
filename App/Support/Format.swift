import Foundation

/// Port of the web's `app/utils/format.ts`.

/// Countdown text such as "1:05". Rounds up so "0:00" only shows when time is truly out.
func formatClock(ms: Double) -> String {
    let totalSeconds = Int((max(0, ms) / 1000).rounded(.up))
    let seconds = totalSeconds % 60
    return "\(totalSeconds / 60):\(seconds < 10 ? "0" : "")\(seconds)"
}

/// Time spent on a question in Spanish notation, e.g. "4,2 s".
func formatSeconds(ms: Double) -> String {
    let value = (max(0, ms) / 1000).formatted(
        .number.precision(.fractionLength(1)).rounded(rule: .toNearestOrAwayFromZero).locale(Locale(identifier: "es_ES"))
    )
    return String(localized: "\(value) s", comment: "Seconds spent on a question, e.g. 4,2 s")
}

/// "+7" / "−2" / "0", with a real minus sign so it is not mistaken for a dash.
func formatSigned(_ value: Int) -> String {
    if value > 0 { return "+\(value)" }
    if value < 0 { return "\u{2212}\(abs(value))" }
    return "0"
}

/// Names a ranking board in a sentence: "60 segundos, dificultad aleatoria" or
/// "120 segundos, dificultad difícil, categoría Ciencias".
func describeBoard(_ duration: GameDuration, _ filter: DifficultyFilter, _ category: QuizCategory?) -> String {
    let seconds = duration.rawValue
    let base: String
    if filter == .random {
        base = String(localized: "\(seconds) segundos, dificultad aleatoria")
    } else {
        base = String(localized: "\(seconds) segundos, dificultad \(filter.rawValue.lowercased())")
    }
    guard let category else { return base }
    return String(localized: "\(base), categoría \(category.rawValue)")
}

/// "1 punto" / "57 puntos" (plural variations live in the String Catalog).
func pointsText(_ points: Int) -> String {
    String(localized: "\(points) puntos", comment: "A number of points")
}
