import FirebaseAnalytics
import FirebaseCore

/// The calls the service makes to Firebase Analytics (swapped for a recorder in tests).
protocol AnalyticsSink: AnyObject {
    func setCollectionEnabled(_ enabled: Bool)
    func setAnalyticsConsent(granted: Bool)
    func resetData()
    func log(_ name: String, _ parameters: [String: AnalyticsValue])
}

/// Firebase Analytics with the web's rules: collection off by default (Info.plist), on only after
/// "Aceptar"; advertising signals always denied; rejecting turns it off and resets the data
/// (the app's equivalent of deleting the GA cookies). No user id is ever set.
final class FirebaseAnalyticsService: AnalyticsService {
    private let sink: any AnalyticsSink
    private var allowed = false

    init(sink: any AnalyticsSink = FirebaseAnalyticsSink()) {
        self.sink = sink
    }

    func apply(_ status: ConsentStatus) {
        let allow = status.allowsAnalytics
        sink.setCollectionEnabled(allow)
        sink.setAnalyticsConsent(granted: allow)
        if !allow && allowed { sink.resetData() }
        allowed = allow
    }

    func track(_ event: AnalyticsEvent) {
        guard allowed else { return }
        sink.log(event.name, event.parameters)
    }
}

final class FirebaseAnalyticsSink: AnalyticsSink {
    private var ready: Bool { FirebaseApp.app() != nil }

    func setCollectionEnabled(_ enabled: Bool) {
        guard ready else { return }
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }

    func setAnalyticsConsent(granted: Bool) {
        guard ready else { return }
        Analytics.setConsent([
            .analyticsStorage: granted ? .granted : .denied,
            .adStorage: .denied,
            .adUserData: .denied,
            .adPersonalization: .denied,
        ])
    }

    func resetData() {
        guard ready else { return }
        Analytics.resetAnalyticsData()
    }

    func log(_ name: String, _ parameters: [String: AnalyticsValue]) {
        guard ready else { return }
        Analytics.logEvent(name, parameters: parameters.mapValues(\.object))
    }
}
