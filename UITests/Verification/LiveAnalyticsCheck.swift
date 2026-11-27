import XCTest

/// Manual check of real analytics: the app as shipped (no fakes, real Firebase), in Firebase debug
/// mode, accepts the analytics prompt, plays an arcade game and shares the result. Runs only when
/// ANALYTICS_CHECK is set (see docs/verification/parity.md); the events are read from the
/// simulator's log and in Firebase's DebugView.
@MainActor
final class LiveAnalyticsCheck: XCTestCase {
    func testLiveArcadeGameAndShareAreLogged() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ANALYTICS_CHECK"] != nil, "manual check")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-FIRDebugEnabled", "-FIRAnalyticsDebugEnabled"]
        app.launch()

        app.buttons["consent.accept"].waitToAppear(20).tap()
        app.buttons["home.playArcade"].waitToAppear().tap()
        app.otherElements["game.screen"].waitToAppear(30)

        // Answer the first option until the clock runs out (60 s).
        let report = app.descendants(matching: .any)["report.screen"]
        let deadline = Date().addingTimeInterval(100)
        while !report.exists && Date() < deadline {
            let answer = app.buttons["answer.0"]
            if answer.exists && answer.isHittable && answer.isEnabled {
                answer.tap()
            } else {
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
        report.waitToAppear()

        let share = app.buttons["Compartir resultado"]
        guard share.waitForExistence(timeout: 5) else {
            throw XCTSkip("the game ended with 0 points, so there is nothing to share: run it again")
        }
        share.tap()
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["Copy", "Copiar"])).firstMatch
        copy.waitToAppear(10).tap()
        app.staticTexts["Resultado copiado. Pégalo donde quieras."].waitToAppear()
        // Give Firebase time to upload in debug mode.
        Thread.sleep(forTimeInterval: 15)
    }
}
