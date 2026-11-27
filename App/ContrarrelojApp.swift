import GoogleSignIn
import SwiftUI

@main
struct ContrarrelojApp: App {
    @State private var env = LaunchOptions.current.uiTesting ? AppEnvironment.uiTesting() : AppEnvironment.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .environment(\.analytics, env.analytics)
                .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { env.play.sceneDidEnterBackground() }
        }
    }
}
