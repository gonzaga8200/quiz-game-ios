import SwiftUI

enum AppTab: Hashable {
    case play, categories, ranking, settings
}

/// The four places of the app. The game opens full screen over them.
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var tab: AppTab = .play
    @State private var showPrivacy = false

    var body: some View {
        TabView(selection: $tab) {
            tabContent(HomeScreen(), screen: "Inicio")
                .tabItem { Label("Jugar", systemImage: "stopwatch") }
                .tag(AppTab.play)
            tabContent(CategoriesScreen(), screen: "Categorías")
                .tabItem { Label("Categorías", systemImage: "square.grid.2x2") }
                .tag(AppTab.categories)
            if env.firebaseAvailable {
                tabContent(RankingScreen(), screen: "Ranking")
                    .tabItem { Label("Ranking", systemImage: "trophy") }
                    .tag(AppTab.ranking)
            }
            tabContent(SettingsScreen(), screen: "Ajustes")
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Color.accentOnGround)
        .overlay(alignment: .bottomLeading) { if !env.play.isPresented { FakeMailBadge() } }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { PrivacyScreen() }
        }
        .fullScreenCover(isPresented: Binding(get: { env.play.isPresented }, set: { if !$0 { env.play.close() } })) {
            PlayCover()
        }
    }

    private func tabContent(_ content: some View, screen: String) -> some View {
        ZStack {
            Color.ground.ignoresSafeArea()
            content
        }
        .foregroundStyle(Color.onGround)
        .trackScreen(screen)
        .consentCard(showPrivacy: $showPrivacy)
    }
}
