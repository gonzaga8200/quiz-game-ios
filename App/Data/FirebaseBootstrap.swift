import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

/// Starts Firebase only when its configuration is bundled. Without `GoogleService-Info.plist`
/// (a fresh clone, CI) the app runs arcade-only on the bundled questions, like the web without
/// its environment variables.
enum FirebaseBootstrap {
    /// Local emulators used by the integration tests (same ports as the web's firebase.json).
    static let emulatorHost = "127.0.0.1"
    static let authEmulatorPort = 9199
    static let firestoreEmulatorPort = 8180

    @discardableResult
    static func configureIfPossible(useEmulators: Bool = false, bundle: Bundle = .main) -> Bool {
        if FirebaseApp.app() != nil { return true }
        guard let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else { return false }
        FirebaseApp.configure(options: options)

        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings() // no stale ranking from disk; questions have their own cache
        if useEmulators {
            settings.host = "\(emulatorHost):\(firestoreEmulatorPort)"
            settings.isSSLEnabled = false
            Auth.auth().useEmulator(withHost: emulatorHost, port: authEmulatorPort)
        }
        Firestore.firestore().settings = settings
        return true
    }
}
