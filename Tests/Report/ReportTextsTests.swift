import Testing
import UIKit
@testable import Contrarreloj

private func report(points: Int, duration: GameDuration = .short, reason: FinishReason = .time, rows: Int = 1,
                    filter: DifficultyFilter = .random, category: QuizCategory? = nil) -> GameReport {
    let base = GameFixtures.report(rights: 1)
    let row = base.rows.first!
    return GameReport(
        points: points, correct: rows, wrong: 0, skipped: 0, bestStreak: 1, breakdown: base.breakdown,
        rows: Array(repeating: row, count: rows), finishReason: reason, duration: duration, filter: filter,
        category: category, celebration: celebrationFor(points: points, duration: duration)
    )
}

struct ReportTextsTests {
    @Test func tierTitlesMatchWeb() {
        #expect(reportHeading(report(points: 150)) == "¡Resultado de campeón!")
        #expect(reportHeading(report(points: 90)) == "¡Gran partida!")
        #expect(reportHeading(report(points: 45)) == "¡Buena partida!")
        #expect(reportHeading(report(points: 15)) == "Nada mal")
        #expect(reportHeading(report(points: 14)) == "Sigue practicando")
        #expect(reportHeading(report(points: 160, duration: .long)) == "¡Buena partida!")
    }

    @Test func exhaustedAndEmptyHeadings() {
        #expect(reportHeading(report(points: 40, reason: .exhausted)) == "¡Has respondido todas las preguntas!")
        #expect(reportHeading(report(points: 0, reason: .exhausted, rows: 0)) == "No hay preguntas con estas opciones")
        #expect(reportHasNoQuestions(report(points: 0, reason: .exhausted, rows: 0)))
        #expect(!reportHasNoQuestions(report(points: 0, reason: .time, rows: 0)))
    }

    @Test func contextLineMatchesWeb() {
        #expect(reportContext(report(points: 1)) == "Partida de 60 segundos con dificultad aleatoria.")
        #expect(reportContext(report(points: 1, duration: .long, filter: .hard)) == "Partida de 120 segundos con dificultad difícil.")
        #expect(reportContext(report(points: 1, category: .music)) == "Partida de 60 segundos de Música.")
    }

    @Test func shareOnlyWithPoints() {
        #expect(reportCanShare(report(points: 3)))
        #expect(!reportCanShare(report(points: 0)))
        #expect(!reportCanShare(report(points: 0, reason: .exhausted, rows: 0)))
    }

    @Test func comboLineTexts() {
        #expect(comboLineLabel(ComboBonusLine(streak: 3, count: 1, points: 2)) == "Racha de 3 (una vez)")
        #expect(comboLineLabel(ComboBonusLine(streak: 5, count: 2, points: 8)) == "Racha de 5 (2 veces)")
    }

    @Test func rankingResultTexts() {
        #expect(rankingResultText(.done(.skipped), board: "60 segundos, dificultad aleatoria") == "Con 0 puntos no entras en el ranking.")
        #expect(rankingResultText(.done(.newBest(best: 48, position: 3)), board: "60 segundos, dificultad aleatoria")
            == "Nuevo récord personal. Estás en el puesto 3 del ranking de 60 segundos, dificultad aleatoria.")
        #expect(rankingResultText(.done(.kept(best: 90, position: 2)), board: "60 segundos, dificultad aleatoria")
            == "Tu mejor puntuación en el ranking de 60 segundos, dificultad aleatoria sigue siendo 90 puntos, en el puesto 2.")
        #expect(rankingResultText(.saving, board: "x") == "Guardando tu puntuación…")
        #expect(rankingResultText(.error, board: "x") == "No se ha podido guardar tu puntuación en el ranking.")
    }
}

struct ShareMethodTests {
    @Test func shareMethodMapping() {
        #expect(shareMethod(for: .copyToPasteboard, completed: true) == "copy")
        #expect(shareMethod(for: .message, completed: true) == "native")
        #expect(shareMethod(for: UIActivity.ActivityType("net.whatsapp.WhatsApp.ShareExtension"), completed: true) == "native")
        #expect(shareMethod(for: .message, completed: false) == nil)
        #expect(shareMethod(for: nil, completed: false) == nil)
    }
}
