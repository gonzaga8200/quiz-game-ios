import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testAppLaunchesWithAWindow() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
    }
}
