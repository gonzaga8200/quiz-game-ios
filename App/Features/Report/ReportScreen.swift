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
                }
                .padding(20)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            // The actions stay pinned at the bottom, in reach of the thumb, however long the report.
            .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
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

    /// Play again (the main action, wide and gold), then share and menu as square icon buttons.
    /// The report scrolls under the bar, which fades into the page at its top edge.
    private var actionBar: some View {
        VStack(spacing: 10) {
            if !shareStatus.isEmpty {
                Text(verbatim: shareStatus)
                    .font(.reading(.subheadline, weight: .bold))
                    .foregroundStyle(Color.onGroundSoft)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            // One row when it fits; with large text, play again gets a row of its own.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    playAgainButton
                    secondaryButtons.buttonStyle(IconButtonStyle())
                }
                VStack(spacing: 10) {
                    playAgainButton
                    HStack(spacing: 10) { secondaryButtons }.buttonStyle(IconButtonStyle(wide: true))
                }
            }
        }
        // The bar stays a bar: past this size the icons show in the large content viewer instead.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .frame(maxWidth: 720)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background {
            ZStack(alignment: .top) {
                Rectangle().fill(.ultraThinMaterial)
                Color.ground.opacity(0.82)
                Rectangle().fill(Color.groundBorder).frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .background(alignment: .top) {
            // A short fade above the bar, so rows dissolve into it instead of being cut.
            LinearGradient(colors: [Color.ground.opacity(0), Color.ground.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .frame(height: 28)
                .offset(y: -28)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .animation(.easeOut(duration: 0.25), value: shareStatus)
    }

    private var playAgainButton: some View {
        Button("Jugar de nuevo", action: onAgain).buttonStyle(PrimaryButtonStyle(large: true))
    }

    /// Styled by the row that holds them: squares beside play again, wide when stacked.
    @ViewBuilder private var secondaryButtons: some View {
        if reportCanShare(report) {
            Button { share() } label: { Label("Compartir resultado", systemImage: "square.and.arrow.up") }
        }
        Button(action: onMenu) { Label("Volver al menú", systemImage: "house") }
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
