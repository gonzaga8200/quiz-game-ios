import Foundation
import Testing
@testable import Contrarreloj

struct TimeoutTests {
    /// Firebase's async APIs ignore cancellation: the limit must hold anyway.
    @Test func timeoutReturnsWithoutWaitingForAnOperationThatIgnoresCancellation() async {
        let start = ContinuousClock.now
        await #expect(throws: TimeoutError.self) {
            try await withTimeout(.milliseconds(50)) {
                await uncancellableWait(seconds: 2)
                return 1
            }
        }
        #expect(ContinuousClock.now - start < .seconds(1))
    }

    @Test func fastOperationWins() async throws {
        let value = try await withTimeout(.seconds(5)) { 42 }
        #expect(value == 42)
    }

    @Test func operationErrorIsRethrown() async {
        await #expect(throws: FakeRemoteError.offline) {
            try await withTimeout(.seconds(5)) { () async throws -> Int in throw FakeRemoteError.offline }
        }
    }

    @Test func cancellingTheCallerEndsTheWait() async {
        let task = Task {
            try await withTimeout(.seconds(30)) {
                await uncancellableWait(seconds: 2)
                return 1
            }
        }
        task.cancel()
        let start = ContinuousClock.now
        let result = await task.result
        #expect(ContinuousClock.now - start < .seconds(1))
        #expect(throws: CancellationError.self) { try result.get() }
    }
}
