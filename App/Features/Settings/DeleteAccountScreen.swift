import SwiftUI

/// Account deletion (App Store Guideline 5.1.1(v)): what is deleted, a confirmation, a fresh
/// sign-in, then the ranking entries and the account go.
struct DeleteAccountScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false
    @State private var deleting = false
    @State private var failed = false
    @State private var done = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Eliminar cuenta")
                    .font(.display(.largeTitle, weight: .heavy, italic: true))
                    .foregroundStyle(Color.accentOnGround)
                    .accessibilityAddTraits(.isHeader)
                if done {
                    Text("Tu cuenta se ha eliminado.").font(.reading(.title3, weight: .bold))
                    Text("Hemos borrado tu cuenta y tus puntuaciones del ranking. Puedes seguir jugando en modo arcade.")
                        .font(.reading(.body))
                    Button("Volver a Ajustes") { dismiss() }.buttonStyle(SecondaryButtonStyle())
                } else {
                    Text("Se borrarán tu cuenta y tus puntuaciones del ranking en todas las tablas. No se puede deshacer.")
                        .font(.reading(.body, weight: .bold))
                    Text("Para confirmarlo tendrás que volver a identificarte con Apple o con Google. Lo que se guarda solo en este dispositivo, como el sonido o las preguntas vistas, se queda hasta que desinstales la app.")
                        .font(.reading(.body))
                    if failed {
                        Text("No se ha podido eliminar tu cuenta. Inténtalo de nuevo.")
                            .font(.reading(.body, weight: .bold))
                            .foregroundStyle(Color.errorOnGround)
                        Button("Reintentar") { delete() }.buttonStyle(SecondaryButtonStyle())
                    }
                    if deleting {
                        ProgressView { Text("Eliminando tu cuenta…") }.frame(maxWidth: .infinity)
                    } else {
                        Button(role: .destructive) { confirming = true } label: {
                            Text("Eliminar mi cuenta")
                                .font(.reading(.body, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundStyle(Color.papel)
                                .background(Color.fallo, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityIdentifier("deleteAccount.confirm")
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color.onGround)
        .background(Color.ground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert("¿Eliminar tu cuenta?", isPresented: $confirming) {
            Button("Eliminar", role: .destructive) { delete() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .trackScreen("Eliminar cuenta")
    }

    private func delete() {
        guard let store = env.rankingStore else { return }
        failed = false
        deleting = true
        Task {
            do {
                let provider = try await AccountDeleter(auth: env.auth, ranking: store).delete()
                env.analytics.track(.accountDeleted(provider))
                done = true
            } catch {
                // Cancelling the fresh sign-in is not an error worth showing.
                failed = authErrorMessage(error) != nil
            }
            deleting = false
        }
    }
}
