import XCTest

@MainActor
final class ReportTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testReportShowsCountsAndBreakdownTotal() {
        let app = launchApp(["-seed", "7", "-bank", "tiny"])
        app.playTinyGame(right: true)
        app.staticTexts["¡Has respondido todas las preguntas!"].waitToAppear()
        XCTAssertEqual(app.staticTexts["report.count.correct"].label, "Correctas: 6")
        XCTAssertEqual(app.staticTexts["report.count.wrong"].label, "Incorrectas: 0")
        XCTAssertEqual(app.staticTexts["report.count.streak"].label, "Mejor racha: 6")
        XCTAssertEqual(app.staticTexts["report.total"].label, "Total: 48")
        XCTAssertTrue(app.buttons["Compartir resultado"].exists)
    }

    func testShareHiddenWithZeroPoints() {
        let app = launchApp(["-seed", "7", "-bank", "tiny"])
        app.playTinyGame(right: false)
        app.staticTexts["report.total"].waitToAppear()
        XCTAssertEqual(app.staticTexts["report.total"].label, "Total: 0")
        XCTAssertFalse(app.buttons["Compartir resultado"].exists)
    }

    func testPlayAgainStartsANewGame() {
        let app = launchApp(["-seed", "7", "-bank", "tiny"])
        app.playTinyGame(right: true)
        app.buttons["Jugar de nuevo"].tap()
        app.otherElements["game.screen"].waitToAppear()
    }

    func testBackToMenuClosesTheGame() {
        let app = launchApp(["-seed", "7", "-bank", "tiny"])
        app.playTinyGame(right: true)
        app.buttons["Volver al menú"].tap()
        app.buttons["home.playArcade"].waitToAppear()
    }
}
