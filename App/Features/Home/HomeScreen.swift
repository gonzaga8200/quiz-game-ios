import SwiftUI

enum HomeRoute: Hashable {
    case setup
}

/// The "Jugar" tab (the web's home): the watch, the title, arcade, competitive mode (or sign-in),
/// the player, and the social links. Wide screens put the watch on the left.
struct HomeScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var path: [HomeRoute] = []
    @State private var signingIn = false
    @State private var openSetupAfterSignIn = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    playerBar
                    // Side by side on wide screens, except at the largest text sizes, where the
                    // right-hand column would be too narrow for the text.
                    if horizontalSize == .regular && !typeSize.isAccessibilitySize {
                        HStack(alignment: .center, spacing: 48) {
                            hero.frame(maxWidth: .infinity)
                            VStack(spacing: 24) { actions; social }.frame(maxWidth: 420)
                        }
                        .padding(.top, 80)
                    } else {
                        hero
                        actions
                        social
                    }
                }
                .padding(20)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .background(Color.ground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { _ in
                SetupScreen { setup in
                    path = []
                    env.play.play(setup)
                }
            }
            .sheet(isPresented: $signingIn, onDismiss: {
                if openSetupAfterSignIn, env.auth.user != nil { path = [.setup] }
                openSetupAfterSignIn = false
            }) {
                SignInSheet(onPrivacy: { showPrivacy = true })
                    .sheet(isPresented: $showPrivacy) { NavigationStack { PrivacyScreen() } }
            }
        }
    }

    // MARK: Parts

    @ViewBuilder private var playerBar: some View {
        HStack(spacing: 10) {
            if let user = env.auth.user {
                Avatar(url: user.photoURL, name: user.displayName, size: 36)
                Text(verbatim: user.displayName).font(.reading(.body, weight: .bold)).lineLimit(1)
                Spacer(minLength: 8)
                Button("Cerrar sesión") { try? env.auth.signOut() }
                    .font(.reading(.subheadline, weight: .bold))
                    .foregroundStyle(Color.accentOnGround)
                    .accessibilityIdentifier("home.signOut")
            } else {
                Spacer()
                if env.auth.isAvailable {
                    Button("Entrar") { signingIn = true }
                        .font(.reading(.body, weight: .bold))
                        .foregroundStyle(Color.accentOnGround)
                        .accessibilityIdentifier("home.signIn")
                }
            }
        }
        .frame(minHeight: 44)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            PocketWatch(progress: 0, idle: true).frame(maxWidth: horizontalSize == .regular ? 300 : 210)
            Text(verbatim: "Contrarreloj")
                .font(.display(size: 56, relativeTo: .largeTitle, weight: .heavy))
                .foregroundStyle(Color.accentOnGround)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityLabel(Text("Contrarreloj: juego de preguntas contra el tiempo"))
                .accessibilityAddTraits(.isHeader)
            Text("Responde todas las preguntas que puedas antes de que se acabe el tiempo.")
                .font(.reading(.title3))
                .foregroundStyle(Color.onGroundSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var actions: some View {
        VStack(spacing: 14) {
            Button { env.play.play(.arcade()) } label: {
                buttonLabel("Jugar arcade", hint: "60 segundos, dificultad aleatoria, sin registro")
            }
            .buttonStyle(PrimaryButtonStyle(large: true))
            .accessibilityIdentifier("home.playArcade")

            if env.auth.isAvailable {
                Button {
                    if env.auth.user != nil {
                        path = [.setup]
                    } else {
                        openSetupAfterSignIn = true
                        signingIn = true
                    }
                } label: {
                    buttonLabel("Modo competitivo", hint: env.auth.user != nil
                        ? "60 o 120 segundos, tú eliges dificultad y categoría"
                        : "Entra con Apple o con Google para competir en el ranking")
                }
                .buttonStyle(SecondaryButtonStyle(large: true))
                .accessibilityIdentifier("home.competitive")
            }
        }
    }

    private func buttonLabel(_ title: LocalizedStringKey, hint: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(title)
            Text(hint).font(.reading(.footnote))
        }
    }

    private var social: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Síguenos").font(.display(.title2, weight: .heavy, italic: true)).foregroundStyle(Color.accentOnGround)
                .accessibilityAddTraits(.isHeader)
            Text("Preguntas nuevas y novedades de Contrarreloj, también en redes.")
                .font(.reading(.subheadline))
                .foregroundStyle(Color.onGroundSoft)
            SocialLinks()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A player's photo, or their initial when there is none (Apple accounts, failed loads).
struct Avatar: View {
    let url: URL?
    let name: String
    var size: CGFloat = 32

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initial
                }
            } else {
                initial
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.oro, lineWidth: 2))
        .accessibilityHidden(true)
    }

    private var initial: some View {
        ZStack {
            Color.oroSombra
            Text(verbatim: String(name.prefix(1)).uppercased()).font(.reading(.headline, weight: .bold)).foregroundStyle(Color.papel)
        }
    }
}
