/// Analytics for previews and UI tests: records what would be sent, with the same consent gate.
final class FakeAnalytics: AnalyticsService {
    private(set) var events: [AnalyticsEvent] = []
    private(set) var status: ConsentStatus = .unset

    func apply(_ status: ConsentStatus) {
        self.status = status
    }

    func track(_ event: AnalyticsEvent) {
        guard status.allowsAnalytics else { return }
        events.append(event)
    }
}
