import SwiftUI

/// The full-screen game: loading, error, the game itself and the report.
struct PlayCover: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let play = env.play
        ZStack {
            Color.ground.ignoresSafeArea()
            switch play.phase {
            case .loading:
                ProgressView {
                    Text("Cargando preguntas…").font(.reading(.body, weight: .bold))
                }
                .tint(Color.onGround)
                .foregroundStyle(Color.onGround)
            case .failed:
                PaperCard {
                    Text("No se han podido cargar las preguntas.").font(.reading(.body, weight: .bold))
                    Button("Reintentar") { play.retry() }.buttonStyle(PrimaryButtonStyle())
                    Button("Volver al menú") { play.close() }.buttonStyle(SecondaryButtonStyle())
                }
                .frame(maxWidth: 520)
                .padding()
            case .playing(let session):
                GameScreen(session: session, onExit: { play.close() })
            case .finished(let report):
                ReportPlaceholder(report: report)
            }
        }
        .overlay(alignment: .bottomLeading) { FakeMailBadge() }
    }
}
