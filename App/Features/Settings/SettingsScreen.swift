import SwiftUI

/// The "Ajustes" tab: account (sign out, delete), sound, analytics consent, privacy and legal
/// texts, contact, social links, hidden players and version.
struct SettingsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @State private var signingIn = false

    var body: some View {
        NavigationStack {
            List {
                account
                Section {
                    Toggle("Sonido", isOn: Binding(get: { !env.sound.isMuted }, set: { env.sound.isMuted = !$0 }))
                        .accessibilityIdentifier("settings.sound")
                } header: { header("Preferencias") }
                .listRowBackground(Color.card)
                privacy
                Section {
                    NavigationLink { ContactScreen() } label: { Label("Contacto", systemImage: "envelope") }
                        .accessibilityIdentifier("settings.contact")
                    socialLink(.instagram)
                    socialLink(.x)
                    NavigationLink { HiddenPlayersScreen() } label: {
                        Label("Jugadores ocultos", systemImage: "eye.slash")
                            .badge(env.hiddenPlayers.uids.count)
                    }
                    .accessibilityIdentifier("settings.hidden")
                } header: { header("Ayuda y redes") }
                .listRowBackground(Color.card)
                Section {
                    LabeledContent("Versión", value: appVersion)
                    Text(verbatim: Legal.copyright)
                } header: { header("Acerca de") }
                .listRowBackground(Color.card)
            }
            .scrollContentBackground(.hidden)
            .background(Color.ground.ignoresSafeArea())
            .foregroundStyle(Color.cardText)
            .tint(Color.acierto)
            .font(.reading(.body))
            .navigationTitle("Ajustes")
            .sheet(isPresented: $signingIn) { SignInSheet() }
        }
    }

    @ViewBuilder private var account: some View {
        Section {
            if let user = env.auth.user {
                HStack(spacing: 12) {
                    Avatar(url: user.photoURL, name: user.displayName, size: 40)
                    VStack(alignment: .leading) {
                        Text(verbatim: user.displayName).font(.reading(.body, weight: .bold))
                        Text(user.provider == .apple ? "Has entrado con Apple" : "Has entrado con Google")
                            .font(.reading(.footnote)).foregroundStyle(Color.cardTextSoft)
                    }
                }
                Button { try? env.auth.signOut() } label: { linkText("Cerrar sesión") }
                    .accessibilityIdentifier("settings.signOut")
                NavigationLink { DeleteAccountScreen() } label: {
                    Text("Eliminar cuenta").foregroundStyle(Color.fallo)
                }
                .accessibilityIdentifier("settings.deleteAccount")
            } else if env.auth.isAvailable {
                Button { signingIn = true } label: { linkText("Entrar con Apple o con Google") }
                    .accessibilityIdentifier("settings.signIn")
            } else {
                Text("El modo competitivo no está disponible en este momento.")
            }
        } header: { header("Cuenta") }
        .listRowBackground(Color.card)
    }

    private var privacy: some View {
        Section {
            Toggle("Estadísticas de uso", isOn: Binding(
                get: { env.consent.status.allowsAnalytics },
                set: { accepted in
                    env.consent.decide(accepted: accepted)
                    env.analytics.apply(env.consent.status)
                }
            ))
            .accessibilityIdentifier("settings.analytics")
            NavigationLink { PrivacyScreen() } label: { Label("Política de privacidad", systemImage: "hand.raised") }
                .accessibilityIdentifier("settings.privacy")
            NavigationLink { LegalNoticeScreen() } label: { Label("Aviso legal", systemImage: "doc.text") }
                .accessibilityIdentifier("settings.legal")
        } header: {
            header("Privacidad")
        } footer: {
            Text("Con las estadísticas activadas medimos de forma anónima cómo se usa el juego con Google Analytics. No se usan para publicidad.")
                .foregroundStyle(Color.onGroundSoft)
        }
        .listRowBackground(Color.card)
    }

    /// Section titles sit on the ground, not on the cards: they take the ground's text colour.
    private func header(_ title: LocalizedStringKey) -> some View {
        Text(title).foregroundStyle(Color.onGroundSoft)
    }

    /// An action inside a card, in the paper's link colour (a list would otherwise tint it).
    private func linkText(_ title: LocalizedStringKey) -> some View {
        Text(title).font(.reading(.body, weight: .bold)).foregroundStyle(Color.enlacePapel)
    }

    private func socialLink(_ network: SocialNetwork) -> some View {
        Link(destination: network.url) {
            HStack {
                Image(network.icon).renderingMode(.template).resizable().frame(width: 20, height: 20)
                Text(verbatim: "\(network.name) · \(network.handle)")
                Spacer()
                Image(systemName: "arrow.up.right").font(.footnote)
            }
        }
        .accessibilityIdentifier("social.\(network.name.lowercased())")
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
