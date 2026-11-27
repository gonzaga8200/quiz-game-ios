import Network
import Observation

/// Whether the device is online, to explain empty or failing screens.
@Observable
final class Connectivity {
    private(set) var isOnline = true
    @ObservationIgnored private let monitor = NWPathMonitor()

    init(monitoring: Bool = true) {
        guard monitoring else { return }
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "com.contrarrelojquiz.connectivity"))
    }
}
