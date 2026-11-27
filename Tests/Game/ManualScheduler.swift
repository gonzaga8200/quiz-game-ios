import Foundation

/// A virtual clock for the game session: `sleep` suspends until `advance` moves time past the
/// deadline, so timers can be tested without waiting (the web's `vi.useFakeTimers`).
final class ManualScheduler {
    private(set) var now: Double = 0
    private var sleepers: [(id: Int, deadline: Double, continuation: CheckedContinuation<Void, Never>)] = []
    private var nextId = 0

    var pending: Int { sleepers.count }

    func sleep(_ duration: Duration) async {
        let (seconds, attoseconds) = duration.components
        let ms = Double(seconds) * 1000 + Double(attoseconds) / 1e15
        nextId += 1
        let id = nextId
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume()
                } else {
                    sleepers.append((id, now + ms, continuation))
                }
            }
        } onCancel: {
            Task { @MainActor in self.wake(id) }
        }
    }

    /// Moves the clock forward, running every timer that falls due, in order.
    func advance(_ ms: Double) async {
        // Let tasks created just before (a feedback timer) register their sleep at the current time.
        await settle()
        let target = now + ms
        while let next = sleepers.min(by: { $0.deadline < $1.deadline }), next.deadline <= target {
            now = next.deadline
            wake(next.id)
            await settle()
        }
        now = target
        await settle()
    }

    /// Jumps the clock without running timers (the app was suspended in the background).
    func jump(_ ms: Double) {
        now += ms
    }

    func settle() async {
        for _ in 0..<30 { await Task.yield() }
    }

    private func wake(_ id: Int) {
        guard let index = sleepers.firstIndex(where: { $0.id == id }) else { return }
        sleepers.remove(at: index).continuation.resume()
    }
}
