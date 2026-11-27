import AuthenticationServices
import SwiftUI

/// Sign-in for competitive mode: Apple and Google with the same weight, the web's notice (14 and
/// over, public name and score) and the error, if any.
struct SignInSheet: View {
    var onPrivacy: () -> Void = {}
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Entra para jugar en modo competitivo")
                .font(.display(.title2, weight: .heavy, italic: true))
                .foregroundStyle(Color.accentOnGround)
                .accessibilityAddTraits(.isHeader)
            AppleSignInButton(dark: colorScheme == .dark) { signIn(.apple) }
                .frame(height: 52)
                .id(colorScheme)
                .accessibilityIdentifier("signIn.apple")
            GoogleSignInButton { signIn(.google) }
            Text("Entra con Apple o con Google para jugar en modo competitivo (mayores de 14 años). Tu nombre, tu foto de perfil y tu puntuación serán visibles en el ranking.")
                .font(.reading(.subheadline))
                .foregroundStyle(Color.onGroundSoft)
            Button("Más información sobre privacidad", action: onPrivacy)
                .font(.reading(.subheadline, weight: .bold))
                .foregroundStyle(Color.accentOnGround)
            if let error {
                Text(verbatim: error).font(.reading(.subheadline, weight: .bold)).foregroundStyle(Color.errorOnGround)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if busy { ProgressView().frame(maxWidth: .infinity) }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.groundRaised.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .disabled(busy)
    }

    private func signIn(_ provider: AuthProvider) {
        error = nil
        busy = true
        // Events carry no personal data: only the method and the error code (like the web).
        env.analytics.track(.loginClick(provider))
        Task {
            do {
                try await env.auth.signIn(with: provider)
                env.analytics.track(.loginSuccess(provider))
                busy = false
                dismiss()
            } catch {
                env.analytics.track(.loginError(provider, code: authErrorCode(error)))
                self.error = authErrorMessage(error)
                busy = false
            }
        }
    }
}

/// Apple's own button (required look), wired to our sign-in flow.
private struct AppleSignInButton: UIViewRepresentable {
    let dark: Bool
    let action: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: dark ? .white : .black)
        button.cornerRadius = 8
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tap() { action() }
    }
}

/// Google's sign-in button: white, the multicolour "G", same size as Apple's.
private struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image("GoogleLogo").resizable().frame(width: 20, height: 20).accessibilityHidden(true)
                Text("Entrar con Google").font(.system(size: 19, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Color(hex: 0x1F1F1F))
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: 0x747775), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier("signIn.google")
    }
}
