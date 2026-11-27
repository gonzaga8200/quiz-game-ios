import SwiftUI

/// Analytics gated by the player's consent: nothing is measured until they accept.
protocol AnalyticsService: AnyObject, Sendable {
    func apply(_ status: ConsentStatus)
    func track(_ event: AnalyticsEvent)
}

nonisolated struct AnalyticsKey: EnvironmentKey {
    static let defaultValue: (any AnalyticsService)? = nil
}

extension EnvironmentValues {
    var analytics: (any AnalyticsService)? {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }
}

private struct ScreenTracking: ViewModifier {
    let name: String
    @Environment(\.analytics) private var analytics

    func body(content: Content) -> some View {
        content.onAppear { analytics?.track(.screenView(name)) }
    }
}

extension View {
    /// Sends `screen_view` when the screen appears (the app's equivalent of the web's `page_view`).
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTracking(name: name))
    }
}
