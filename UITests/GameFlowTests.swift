import XCTest

@MainActor
final class GameFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func startArcade(_ extra: [String] = []) -> XCUIApplication {
        let app = launchApp(["-seed", "7", "-bank", "tiny"] + extra)
        app.buttons["home.playArcade"].waitToAppear().tap()
        app.otherElements["game.screen"].waitToAppear()
        return app
    }

    private func answer(_ app: XCUIApplication, containing text: String) {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        button.waitToAppear()
        button.tap()
    }

    private func questionText(_ app: XCUIApplication) -> String {
        app.staticTexts["question.text"].waitToAppear().label
    }

    private func waitForNewQuestion(_ app: XCUIApplication, after previous: String) {
        let predicate = NSPredicate(format: "label != %@", previous)
        expectation(for: predicate, evaluatedWith: app.staticTexts["question.text"])
        waitForExpectations(timeout: 5)
    }

    func testArcadeGameReachesReport() {
        let app = startArcade()
        for _ in 0..<5 {
            let previous = questionText(app)
            answer(app, containing: "Correcta")
            waitForNewQuestion(app, after: previous)
        }
        answer(app, containing: "Correcta")
        app.otherElements["report.screen"].waitToAppear()
    }

    func testWrongAnswerShowsStampAndRevealsCorrect() {
        let app = startArcade(["-feedbackMs", "4000"])
        answer(app, containing: "Falsa uno")
        app.staticTexts["¡Fallo!"].waitToAppear(2)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Esta era la respuesta correcta'")).firstMatch.exists)
    }

    func testSkipShowsFreeSkipsLeft() {
        let app = startArcade()
        let skip = app.buttons["skip"].waitToAppear()
        XCTAssertTrue(skip.label.contains("Te quedan 2 pases gratis"))
        let previous = questionText(app)
        skip.tap()
        waitForNewQuestion(app, after: previous)
        XCTAssertTrue(app.buttons["skip"].label.contains("Te queda 1 pase gratis"))
    }

    func testReportQuestionPausesClock() {
        let app = startArcade()
        let id = questionText(app)
        XCTAssertFalse(id.isEmpty)
        app.buttons["reportQuestion"].waitToAppear().tap()
        app.staticTexts["Reportar esta pregunta"].waitToAppear()
        let clock = app.staticTexts["hud.clock"].label
        sleep(2)
        XCTAssertEqual(app.staticTexts["hud.clock"].label, clock)
        app.buttons["Abrir mi correo"].tap()
        let subject = app.staticTexts["fakeMail.subject"].waitToAppear()
        XCTAssertTrue(subject.label.hasPrefix("Pregunta con respuesta incorrecta (pregunta prueba-"))
    }

    func testExitAsksForConfirmation() {
        let app = startArcade()
        app.buttons["exitGame"].tap()
        app.buttons["Seguir jugando"].waitToAppear().tap()
        XCTAssertTrue(app.otherElements["game.screen"].exists)
        app.buttons["exitGame"].tap()
        app.buttons["Abandonar"].waitToAppear().tap()
        app.buttons["home.playArcade"].waitToAppear()
    }

    func testKeyboardShortcutsAnswerAndSkip() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("hardware keyboard shortcuts are an iPad feature") }
        let app = startArcade(["-feedbackMs", "4000"])
        let previous = questionText(app)
        app.typeKey("p", modifierFlags: [])
        waitForNewQuestion(app, after: previous)
        XCTAssertTrue(app.buttons["skip"].label.contains("Te queda 1 pase gratis"))
        app.typeKey("1", modifierFlags: [])
        app.staticTexts["card.summary"].waitToAppear(2)
    }

    func testAnswersAreHittableAtAccessibilityXXXL() {
        let app = startArcade(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        for id in ["answer.0", "answer.1", "answer.2", "answer.3", "skip"] {
            let element = app.buttons[id].waitToAppear()
            var swipes = 0
            while !element.isHittable && swipes < 6 {
                app.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(element.isHittable, "\(id) is not reachable at the largest text size")
        }
    }

    func testRotationKeepsTheGameState() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("rotation mid-question is checked on iPad") }
        let app = startArcade()
        answer(app, containing: "Correcta")
        sleep(1)
        let question = questionText(app)
        let score = app.staticTexts["hud.score"].label
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        XCTAssertEqual(questionText(app), question)
        XCTAssertEqual(app.staticTexts["hud.score"].label, score)
        XCUIDevice.shared.orientation = .portrait
    }
}
