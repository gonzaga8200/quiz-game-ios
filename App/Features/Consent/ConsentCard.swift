import SwiftUI

/// The app's version of the web's cookie banner: non-blocking, with "Aceptar" and "Rechazar" of
/// the same size and style, and a link to the privacy policy.
struct ConsentCard: View {
    let onAccept: () -> Void
    let onReject: () -> Void
    let onMoreInfo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estadísticas de uso")
                .font(.display(.title3, weight: .heavy, italic: true))
                .accessibilityAddTraits(.isHeader)
            Text("Guardamos en tu dispositivo lo imprescindible para que funcione el inicio de sesión y para recordar tus preferencias. Iniciar sesión no depende de lo que elijas aquí.")
            Text("¿Nos dejas usar Google Analytics para medir cómo se usa el juego? Son datos estadísticos y no los usamos para publicidad.")
            // Same style and size on purpose: accepting and rejecting must be equally easy.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { buttons }
                VStack(spacing: 12) { buttons }
            }
            Button("Más información en la política de privacidad", action: onMoreInfo)
                .font(.reading(.subheadline, weight: .bold))
                .foregroundStyle(Color.enlacePapel)
        }
        .font(.reading(.subheadline))
        .foregroundStyle(Color.cardText)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.card).shadow(color: .black.opacity(0.35), radius: 12, y: 6))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.oroSombra, lineWidth: 2))
        .frame(maxWidth: 560)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var buttons: some View {
        Button("Aceptar", action: onAccept)
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("consent.accept")
        Button("Rechazar", action: onReject)
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("consent.reject")
    }
}

/// Shows the consent card at the bottom of a tab while the player has not decided.
private struct ConsentHost: ViewModifier {
    @Environment(AppEnvironment.self) private var env
    @Binding var showPrivacy: Bool

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            if env.consent.needsAsking {
                ConsentCard(
                    onAccept: { decide(true) },
                    onReject: { decide(false) },
                    onMoreInfo: { showPrivacy = true }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func decide(_ accepted: Bool) {
        env.consent.decide(accepted: accepted)
        env.analytics.apply(env.consent.status)
    }
}

extension View {
    func consentCard(showPrivacy: Binding<Bool>) -> some View {
        modifier(ConsentHost(showPrivacy: showPrivacy))
    }
}
