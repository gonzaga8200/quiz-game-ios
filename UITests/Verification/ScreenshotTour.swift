import XCTest

/// Screenshots of every flow for review (docs/verification/screenshots). Runs only from
/// scripts/screenshots.sh, which sets SCREENSHOTS_DIR, the file prefix and the appearance.
@MainActor
final class ScreenshotTour: XCTestCase {
    private let env = ProcessInfo.processInfo.environment

    override func setUpWithError() throws {
        guard ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] != nil else {
            throw XCTSkip("run it with scripts/screenshots.sh")
        }
        continueAfterFailure = false
    }

    private func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 0.8) // let transitions settle
        let folder = URL(fileURLWithPath: env["SCREENSHOTS_DIR"] ?? NSTemporaryDirectory())
        let file = folder.appending(path: "\(env["SCREENSHOTS_PREFIX"] ?? "")\(name).png")
        XCTAssertNoThrow(try XCUIScreen.main.screenshot().pngRepresentation.write(to: file))
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    func testTour() throws {
        XCUIDevice.shared.orientation = .portrait
        var app = launchApp(["-seed", "7", "-feedbackMs", "4000", "-rankingFake", "seeded"], consent: "unset")
        app.buttons["consent.accept"].waitToAppear()
        shot("01-home-consent")
        app.buttons["consent.reject"].tap()
        shot("02-home")

        app.buttons["home.playArcade"].tap()
        app.otherElements["game.screen"].waitToAppear()
        app.staticTexts["question.text"].waitToAppear()
        shot("03-game")
        if isPad {
            XCUIDevice.shared.orientation = .landscapeLeft
            shot("03b-game-landscape")
            XCUIDevice.shared.orientation = .portrait
        }
        app.buttons["answer.1"].tap()
        shot("04-game-answered")
        app.buttons["exitGame"].waitToAppear().tap()
        app.buttons["Abandonar"].waitToAppear().tap()

        app.tab("Categorías").waitToAppear().tap()
        app.buttons["categories.card.ciencias"].waitToAppear()
        shot("05-categories")
        app.buttons["categories.card.ciencias"].tap()
        app.staticTexts["Preguntas de ciencias con respuestas"].waitToAppear()
        shot("06-category")

        app.tab("Ranking").tap()
        app.otherElements["ranking.row.u1"].waitToAppear()
        shot("07-ranking")

        app.tab("Ajustes").tap()
        app.switches["settings.analytics"].waitToAppear()
        shot("08-settings")
        let privacy = app.buttons["settings.privacy"]
        var swipes = 0
        while !(privacy.exists && privacy.isHittable) && swipes < 6 { app.swipeUp(); swipes += 1 }
        privacy.tap()
        app.staticTexts["Política de privacidad"].waitToAppear()
        shot("09-privacy")

        app = launchApp(["-bank", "tiny", "-seed", "7"])
        app.playTinyGame(right: true)
        app.descendants(matching: .any)["report.screen"].waitToAppear()
        Thread.sleep(forTimeInterval: 4) // after the confetti
        shot("10-report")

        app = launchApp(["-fakeUser", "google", "-rankingFake", "seeded"])
        app.buttons["home.competitive"].waitToAppear()
        shot("11-home-signed-in")
        app.buttons["home.competitive"].tap()
        app.buttons["setup.start"].waitToAppear()
        shot("12-setup")
        app.tab("Ajustes").tap()
        app.buttons["settings.deleteAccount"].waitToAppear().tap()
        app.buttons["deleteAccount.confirm"].waitToAppear()
        shot("13-delete-account")

        app = launchApp()
        app.buttons["home.signIn"].waitToAppear().tap()
        app.buttons["signIn.google"].waitToAppear()
        shot("14-sign-in")
    }

    func testGameAtLargestText() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = launchApp(["-seed", "7", "-feedbackMs", "4000",
                             "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        app.buttons["home.playArcade"].waitToAppear()
        shot("20-ax5-home")
        app.buttons["home.playArcade"].tap()
        app.staticTexts["question.text"].waitToAppear()
        shot("21-ax5-game")
        let answer = app.buttons["answer.0"]
        var swipes = 0
        while !answer.isHittable && swipes < 4 { app.swipeUp(); swipes += 1 }
        answer.tap()
        shot("22-ax5-game-answered")
    }
}
