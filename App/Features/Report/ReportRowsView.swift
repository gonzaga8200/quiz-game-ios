import SwiftUI

/// "Pregunta a pregunta": every question of the game; for misses and skips also the right answer
/// and the explanation (the web's ReportQuestionList).
struct ReportRowsView: View {
    let rows: [ReportRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pregunta a pregunta")
                .font(.display(.title2, weight: .heavy, italic: true))
                .foregroundStyle(Color.accentOnGround)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                ReportRowView(row: row)
            }
        }
    }
}

private struct ReportRowView: View {
    let row: ReportRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                badge
                Text(verbatim: "\(row.category.rawValue), \(row.difficulty.rawValue), \(formatSeconds(ms: row.timeMs))")
                    .font(.reading(.footnote))
                    .foregroundStyle(Color.cardTextSoft)
            }
            Text(verbatim: row.text).font(.reading(.body, weight: .bold))
            if row.result != .correct {
                if let chosen = row.chosenAnswer {
                    (Text("Tu respuesta: ") + Text(verbatim: chosen).bold()).font(.reading(.subheadline))
                }
                (Text("Respuesta correcta: ") + Text(verbatim: row.correctAnswer).bold()).font(.reading(.subheadline))
                Text(verbatim: row.explanation).font(.reading(.subheadline, italic: true)).foregroundStyle(Color.cardTextSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .foregroundStyle(Color.cardText)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .leading) {
            Rectangle().fill(accent).frame(width: 6).clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8))
        }
        .accessibilityElement(children: .combine)
    }

    private var accent: Color {
        switch row.result {
        case .correct: .aciertoLinea
        case .wrong: .fallo
        case .skipped: .pasarClaroBorde
        }
    }

    private var badge: some View {
        HStack(spacing: 4) {
            switch row.result {
            case .correct: Image(systemName: "checkmark")
            case .wrong: Image(systemName: "xmark")
            case .skipped: Image(systemName: "arrow.uturn.forward")
            }
            Text(row.result == .correct ? "Correcta" : row.result == .wrong ? "Incorrecta" : "Pasada")
        }
        .font(.reading(.footnote, weight: .bold))
        .foregroundStyle(Color.papel)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(accent == .pasarClaroBorde ? Color.pasarOscuro : (row.result == .correct ? Color.acierto : Color.fallo), in: Capsule())
    }
}
