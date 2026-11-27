import Foundation

/// Port of the web's `app/utils/share.ts`.
struct ShareInput {
    let points: Int
    let duration: GameDuration
    let filter: DifficultyFilter
    /// Set when the game was limited to one category.
    let category: QuizCategory?
    /// First emoji of the result's celebration.
    let emoji: String
}

/// The message a player shares: only the result (points, time, what was played), never a name.
func shareText(_ input: ShareInput) -> String {
    var context = ["\(input.duration.rawValue) s"]
    if let category = input.category {
        context.append(category.rawValue)
    } else if input.filter != .random {
        context.append(String(localized: "dificultad \(input.filter.rawValue.lowercased())"))
    }
    let points = pointsText(input.points)
    let played = context.joined(separator: ", ")
    return String(localized: "\(input.emoji) He conseguido \(points) en Contrarreloj, el juego de preguntas contra el reloj (\(played)). ¿Me superas?")
}

/// Where a shared link lands: the page of the category played, or the home page.
func shareURL(category: QuizCategory?) -> URL {
    guard let category else { return AppLinks.site.appending(path: "/") }
    return AppLinks.site.appending(path: "preguntas/\(category.urlSlug)")
}
