import SwiftUI

struct ReportTarget: Identifiable {
    let id: String
    let text: String
    let category: QuizCategory
    let difficulty: Difficulty
}

/// Reporting a question (the web's ReportQuestionDialog): the game is paused, and the player's
/// mail opens with the question already written.
struct ReportQuestionSheet: View {
    let target: ReportTarget
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reportar esta pregunta")
                .font(.display(.title2, weight: .heavy, italic: true))
                .foregroundStyle(Color.accentOnGround)
                .accessibilityAddTraits(.isHeader)
            Text("La partida está en pausa. Se abrirá tu correo con la pregunta ya escrita: añade lo que veas y envíalo desde allí.")
                .font(.reading(.subheadline))
                .foregroundStyle(Color.onGroundSoft)
            Text(verbatim: target.text)
                .font(.display(.headline, italic: true))
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(Color.oro).frame(width: 3) }
            Button("Abrir mi correo", action: onSend).buttonStyle(PrimaryButtonStyle(large: true))
            Button("Cancelar", action: onCancel).buttonStyle(SecondaryButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(Color.onGround)
        .background(Color.groundRaised.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
