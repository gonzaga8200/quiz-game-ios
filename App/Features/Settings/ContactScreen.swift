import SwiftUI

/// Contact (the web's /contacto): a reason opens the player's mail with the subject written.
struct ContactScreen: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("¿Tienes una sugerencia o has visto algo raro?")
                    .font(.display(.largeTitle, weight: .heavy, italic: true))
                    .foregroundStyle(Color.accentOnGround)
                    .accessibilityAddTraits(.isHeader)
                Text("Nos importa lo que opinas. Elige el motivo: se abrirá tu correo con el asunto ya escrito y tú pones el resto. Lo leemos todo.")
                    .font(.reading(.body))
                VStack(spacing: 12) {
                    reason(.suggestion)
                    reason(.wrongAnswer)
                    reason(.other)
                }
                Text("¿Prefieres escribir tú el asunto? Escríbenos a [\(AppLinks.contactEmail)](mailto:\(AppLinks.contactEmail)).")
                    .font(.reading(.body))
                    .tint(Color.accentOnGround)
            }
            .padding(20)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.onGround)
        .background(Color.ground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("Contacto")
    }

    private func reason(_ reason: ContactReason) -> some View {
        Button(reason.label) { Task { _ = await env.mail.compose(reason.draft) } }
            .buttonStyle(SecondaryButtonStyle())
    }
}
