import SwiftUI

/// "Respuestas" (counts) and "Desglose de puntos" (where the points came from).
struct ReportCountsView: View {
    let report: GameReport

    var body: some View {
        PaperCard {
            Text("Respuestas").font(.display(.title2, weight: .heavy, italic: true)).accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], alignment: .leading, spacing: 12) {
                tile(String(localized: "Correctas"), report.correct, id: "correct")
                tile(String(localized: "Incorrectas"), report.wrong, id: "wrong")
                tile(String(localized: "Pasadas"), report.skipped, id: "skipped")
                tile(String(localized: "Mejor racha"), report.bestStreak, id: "streak")
            }
        }
    }

    private func tile(_ label: String, _ value: Int, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: label).font(.reading(.subheadline)).foregroundStyle(Color.cardTextSoft)
            Text(verbatim: "\(value)").font(.display(.largeTitle, weight: .heavy, italic: true)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(Text(verbatim: "\(label): \(value)"))
        .accessibilityIdentifier("report.count.\(id)")
    }
}

struct ReportBreakdownView: View {
    let report: GameReport

    var body: some View {
        let b = report.breakdown
        PaperCard {
            Text("Desglose de puntos").font(.display(.title2, weight: .heavy, italic: true)).accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                line(String(localized: "Aciertos"), formatSigned(b.correctPoints))
                ForEach(b.comboBonuses, id: \.streak) { bonus in
                    line(comboLineLabel(bonus), formatSigned(bonus.points))
                }
                line(String(localized: "Penalización por fallos"), formatSigned(-b.wrongPenalty))
                line(String(localized: "Penalización por pasar"), formatSigned(-b.skipPenalty))
                Rectangle().fill(Color.tinta).frame(height: 3).padding(.top, 4)
                HStack {
                    Text("Total")
                    Spacer()
                    Text(verbatim: "\(report.points)").monospacedDigit()
                }
                .font(.reading(.title3, weight: .bold))
                .padding(.top, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(Text("Total: \(report.points)"))
                .accessibilityIdentifier("report.total")
            }
        }
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: label).font(.reading(.body))
            Spacer()
            Text(verbatim: value).font(.reading(.body, weight: .bold)).monospacedDigit()
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.papelLinea).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}
