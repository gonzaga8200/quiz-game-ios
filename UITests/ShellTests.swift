import XCTest

@MainActor
final class ShellTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testFourTabsExist() {
        let app = launchApp()
        for name in ["Jugar", "Categorías", "Ranking", "Ajustes"] {
            XCTAssertTrue(app.tab(name).waitForExistence(timeout: 10), "missing tab \(name)")
        }
    }

    func testNoFirebaseHidesRankingTab() {
        let app = launchApp(["-noFirebase"])
        app.tab("Jugar").waitToAppear()
        XCTAssertFalse(app.tab("Ranking").exists)
    }

    func testConsentCardButtonsHaveSameSizeAndRejectHidesIt() {
        let app = launchApp(consent: "unset")
        let accept = app.buttons["consent.accept"].waitToAppear()
        let reject = app.buttons["consent.reject"]
        XCTAssertEqual(accept.frame.size, reject.frame.size)
        reject.tap()
        XCTAssertTrue(accept.waitForNonExistence(timeout: 5))
    }

    func testAcceptingConsentHidesTheCard() {
        let app = launchApp(consent: "unset")
        app.buttons["consent.accept"].waitToAppear().tap()
        XCTAssertTrue(app.buttons["consent.reject"].waitForNonExistence(timeout: 5))
    }

    func testPlayArcadeShowsTheGame() {
        let app = launchApp(["-bank", "tiny"])
        app.buttons["home.playArcade"].waitToAppear().tap()
        app.otherElements["game.screen"].waitToAppear()
    }

    func testBankErrorOffersRetryAndBack() {
        let app = launchApp(["-bank", "failing"])
        app.buttons["home.playArcade"].waitToAppear().tap()
        app.buttons["Reintentar"].waitToAppear()
        app.buttons["Volver al menú"].tap()
        XCTAssertTrue(app.buttons["home.playArcade"].waitForExistence(timeout: 5))
    }
}
