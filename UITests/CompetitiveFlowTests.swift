import XCTest

@MainActor
final class CompetitiveFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func text(containing fragment: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
    }

    /// Answers right until the report shows.
    private func playToReport(_ app: XCUIApplication) {
        app.otherElements["game.screen"].waitToAppear()
        for _ in 0..<8 {
            if app.otherElements["report.screen"].exists { break }
            let right = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Correcta'")).firstMatch
            guard right.waitForExistence(timeout: 3) else { break }
            right.tap()
            _ = app.otherElements["report.screen"].waitForExistence(timeout: 1.5)
        }
        app.otherElements["report.screen"].waitToAppear()
    }

    private func setUpGame(_ app: XCUIApplication, duration: String, filter: String, category: String) {
        app.buttons["home.competitive"].waitToAppear().tap()
        app.buttons["setup.duration.\(duration)"].waitToAppear().tap()
        app.buttons["setup.filter.\(filter)"].tap()
        let tile = app.buttons["setup.category.\(category)"]
        var swipes = 0
        while !tile.isHittable && swipes < 4 { app.swipeUp(); swipes += 1 }
        tile.tap()
    }

    func testSignInShowsAgeAndPublicNameNotice() {
        let app = launchApp(["-bank", "tiny"])
        app.buttons["home.competitive"].waitToAppear().tap()
        text(containing: "mayores de 14 años", in: app).waitToAppear()
        XCTAssertTrue(text(containing: "visibles en el ranking", in: app).exists)
        XCTAssertTrue(app.buttons["signIn.google"].exists)
        XCTAssertTrue(app.buttons["signIn.apple"].exists)
    }

    func testFakeSignInUnlocksCompetitive() {
        let app = launchApp(["-bank", "tiny"])
        app.buttons["home.competitive"].waitToAppear().tap()
        app.buttons["signIn.google"].waitToAppear().tap()
        app.staticTexts["Modo competitivo"].waitToAppear()
        app.buttons["setup.start"].waitToAppear()
    }

    func testCompetitiveGameShowsNewPersonalBest() {
        let app = launchApp(["-bank", "tiny", "-seed", "3", "-fakeUser", "google"])
        setUpGame(app, duration: "120", filter: "medio", category: "ciencias")
        XCTAssertEqual(app.staticTexts["setup.recap"].label, "120 segundos, dificultad medio, categoría Ciencias")
        app.buttons["setup.start"].tap()
        playToReport(app)
        text(containing: "Nuevo récord personal", in: app).waitToAppear()
        XCTAssertTrue(text(containing: "puesto 1 del ranking de 120 segundos, dificultad medio, categoría Ciencias", in: app).exists)
    }

    func testRankingSaveErrorOffersRetry() {
        let app = launchApp(["-bank", "tiny", "-seed", "3", "-fakeUser", "google", "-rankingFake", "failing"])
        setUpGame(app, duration: "60", filter: "medio", category: "ciencias")
        app.buttons["setup.start"].tap()
        playToReport(app)
        text(containing: "No se ha podido guardar tu puntuación", in: app).waitToAppear()
        XCTAssertTrue(app.buttons["Reintentar"].exists)
    }

    func testEmptyCombinationShowsNoQuestionsReport() {
        let app = launchApp(["-bank", "tiny", "-fakeUser", "google"])
        setUpGame(app, duration: "60", filter: "dificil", category: "musica")
        app.buttons["setup.start"].tap()
        app.staticTexts["No hay preguntas con estas opciones"].waitToAppear()
        XCTAssertFalse(app.otherElements["report.ranking"].exists)
    }

    func testSignOutFromHomeShowsEntrar() {
        let app = launchApp(["-bank", "tiny", "-fakeUser", "google"])
        app.buttons["home.signOut"].waitToAppear().tap()
        app.buttons["home.signIn"].waitToAppear()
    }

    /// While one sign-in is under way the other provider's button is off (Apple's is a UIKit button
    /// that SwiftUI's .disabled does not reach).
    func testAppleButtonIsDisabledWhileSigningIn() {
        let app = launchApp(["-slowSignIn"])
        app.buttons["home.signIn"].waitToAppear().tap()
        app.buttons["signIn.google"].waitToAppear().tap()
        let apple = app.buttons["signIn.apple"]
        XCTAssertTrue(apple.waitForExistence(timeout: 2))
        XCTAssertFalse(apple.isEnabled, "Apple's button must be off while signing in with Google")
    }
}
