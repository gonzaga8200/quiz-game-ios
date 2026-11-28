import SwiftUI

/// The end-of-game report (the web's ReportScreen): title by result, points, ranking result for
/// competitive games, counts, breakdown, question by question, and play again / share / menu.
struct ReportScreen: View {
    let report: GameReport
    let setup: GameSetup
    let submission: SubmissionState?
    let onRetry: () -> Void
    let onShared: (String) -> Void
    let onAgain: () -> Void
    let onMenu: () -> Void

    @State private var shareStatus = ""
    @AccessibilityFocusState private var titleFocused: Bool

    private var empty: Bool { reportHasNoQuestions(report) }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if empty {
                        PaperCard {
                            Text("No hay preguntas para esta combinación. Prueba con otra dificultad u otra categoría.")
                                .font(.reading(.body))
                        }
                    } else {
                        if let submission {
                            RankingResultView(state: submission, board: describeBoard(report.duration, report.filter, report.category),
                                              onRetry: onRetry)
                        }
                        ReportCountsView(report: report)
                        ReportBreakdownView(report: report)
                        ReportRowsView(rows: report.rows)
                    }
                    actions
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            if !empty {
                Confetti(kind: .emojis(report.celebration.emojis), count: max(8, report.celebration.particleCount / 4), duration: 3)
            }
            StatusBarBackdrop()
        }
        .foregroundStyle(Color.onGround)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("report.screen")
        .onAppear { titleFocused = true }
        .trackScreen("Informe")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !empty, let emoji = report.celebration.emojis.first {
                Text(verbatim: emoji).font(.system(size: 56)).accessibilityHidden(true)
            }
            Text(verbatim: reportHeading(report))
                .font(.display(.largeTitle, weight: .heavy, italic: true))
                .foregroundStyle(Color.accentOnGround)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
            if !empty {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(verbatim: "\(report.points)")
                        .font(.display(size: 88, relativeTo: .largeTitle, weight: .heavy, italic: true))
                        .monospacedDigit()
                    Text(report.points == 1 ? "punto" : "puntos").font(.display(.title, weight: .bold, italic: true))
                }
                .accessibilityElement(children: .combine)
                Text(verbatim: reportContext(report)).font(.reading(.body)).foregroundStyle(Color.onGroundSoft)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button("Jugar de nuevo", action: onAgain).buttonStyle(PrimaryButtonStyle(large: true))
            if reportCanShare(report) {
                Button("Compartir resultado") { share() }.buttonStyle(SecondaryButtonStyle(large: true))
            }
            Button("Volver al menú", action: onMenu).buttonStyle(SecondaryButtonStyle(large: true))
            if !shareStatus.isEmpty {
                Text(verbatim: shareStatus).font(.reading(.body, weight: .bold)).foregroundStyle(Color.onGroundSoft)
            }
        }
    }

    private func share() {
        let text = shareText(ShareInput(points: report.points, duration: report.duration, filter: report.filter,
                                        category: report.category, emoji: report.celebration.emojis.first ?? ""))
        ShareController.share(text: text, url: shareURL(category: report.category)) { method in
            guard let method else { return }
            onShared(method)
            shareStatus = method == "copy" ? String(localized: "Resultado copiado. Pégalo donde quieras.") : ""
        }
    }
}
