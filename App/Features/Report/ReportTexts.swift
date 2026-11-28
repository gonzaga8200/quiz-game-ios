import Foundation

/// Saving a competitive game to the ranking, as the report shows it.
nonisolated enum SubmissionState: Equatable, Sendable {
    case idle
    case saving
    case done(SubmitResult)
    case error
}

/// No question matched the chosen options (the bank had none for that combination).
func reportHasNoQuestions(_ report: GameReport) -> Bool {
    report.rows.isEmpty && report.finishReason == .exhausted
}

/// The title of the report (texts of the web's ReportScreen.vue).
func reportHeading(_ report: GameReport) -> String {
    if reportHasNoQuestions(report) { return String(localized: "No hay preguntas con estas opciones") }
    if report.finishReason == .exhausted { return String(localized: "¡Has respondido todas las preguntas!") }
    switch report.celebration.tier {
    case .trophy: return String(localized: "¡Resultado de campeón!")
    case .party: return String(localized: "¡Gran partida!")
    case .clap: return String(localized: "¡Buena partida!")
    case .thumbs: return String(localized: "Nada mal")
    case .try: return String(localized: "Sigue practicando")
    }
}

/// "Partida de 60 segundos con dificultad aleatoria." / "Partida de 60 segundos de Música."
func reportContext(_ report: GameReport) -> String {
    let seconds = report.duration.rawValue
    if let category = report.category {
        return String(localized: "Partida de \(seconds) segundos de \(category.rawValue).")
    }
    let level = report.filter == .random
        ? String(localized: "dificultad aleatoria")
        : String(localized: "dificultad \(report.filter.rawValue.lowercased())")
    return String(localized: "Partida de \(seconds) segundos con \(level).")
}

/// Only a result that scored can be shared.
func reportCanShare(_ report: GameReport) -> Bool {
    !reportHasNoQuestions(report) && report.points > 0
}

/// "Racha de 3 (una vez)" / "Racha de 5 (2 veces)".
func comboLineLabel(_ line: ComboBonusLine) -> String {
    let times = line.count == 1 ? String(localized: "una vez") : String(localized: "\(line.count) veces")
    return String(localized: "Racha de \(line.streak) (\(times))")
}

/// The ranking box of a competitive report (texts of the web's RankingResult.vue).
func rankingResultText(_ state: SubmissionState, board: String) -> String {
    switch state {
    case .idle, .saving:
        return String(localized: "Guardando tu puntuación…")
    case .done(.skipped):
        return String(localized: "Con 0 puntos no entras en el ranking.")
    case .done(.newBest(_, let position)):
        return String(localized: "Nuevo récord personal.") + " "
            + String(localized: "Estás en el puesto \(position) del ranking de \(board).")
    case .done(.kept(let best, let position)):
        return String(localized: "Tu mejor puntuación en el ranking de \(board) sigue siendo \(pointsText(best)), en el puesto \(position).")
    case .error:
        return String(localized: "No se ha podido guardar tu puntuación en el ranking.")
    }
}
