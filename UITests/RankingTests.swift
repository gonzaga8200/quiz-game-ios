import XCTest

@MainActor
final class RankingTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func openRanking(_ mode: String, signedIn: Bool = true) -> XCUIApplication {
        let app = launchApp(["-rankingFake", mode] + (signedIn ? ["-fakeUser", "google"] : []))
        app.tab("Ranking").waitToAppear().tap()
        return app
    }

    func testFiltersSwitchBoard() {
        let app = openRanking("seeded")
        XCTAssertEqual(app.staticTexts["ranking.heading"].waitToAppear().label, "60 segundos, dificultad aleatoria")
        app.otherElements["ranking.row.u1"].waitToAppear()
        app.buttons["120 s"].tap()
        let heading = app.staticTexts["ranking.heading"]
        expectation(for: NSPredicate(format: "label == '120 segundos, dificultad aleatoria'"), evaluatedWith: heading)
        waitForExpectations(timeout: 5)
        app.otherElements["ranking.row.u4"].waitToAppear()
    }

    func testTiesSharePositionAndMarkTheCurrentPlayer() {
        let app = openRanking("seeded")
        XCTAssertEqual(app.otherElements["ranking.row.u1"].waitToAppear().label, "Puesto 1: Ana, 140 puntos")
        XCTAssertEqual(app.otherElements["ranking.row.u2"].label, "Puesto 2: Luis, 98 puntos")
        XCTAssertEqual(app.otherElements["ranking.row.u3"].label, "Puesto 2: Marta, 98 puntos")
        XCTAssertEqual(app.otherElements["ranking.row.me"].label, "Puesto 4: Yo (tú), 70 puntos")
        XCTAssertFalse(app.buttons["ranking.more.me"].exists)
    }

    func testEmptyBoardMessage() {
        let app = openRanking("empty")
        app.staticTexts["Todavía no hay puntuaciones aquí. Juega en modo competitivo para ser el primero."].waitToAppear()
    }

    func testErrorThenRetry() {
        let app = openRanking("failing")
        app.staticTexts["No se ha podido cargar el ranking."].waitToAppear()
        app.buttons["Reintentar"].tap()
        app.staticTexts["No se ha podido cargar el ranking."].waitToAppear()
    }

    func testHidePlayerRemovesRow() {
        let app = openRanking("seeded")
        app.buttons["ranking.more.u2"].waitToAppear().tap()
        app.buttons["Ocultar jugador"].waitToAppear().tap()
        XCTAssertTrue(app.otherElements["ranking.row.u2"].waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["ranking.row.u3"].label, "Puesto 2: Marta, 98 puntos")
    }

    func testReportPlayerOpensMail() {
        let app = openRanking("seeded")
        app.buttons["ranking.more.u1"].waitToAppear().tap()
        app.buttons["Reportar jugador"].waitToAppear().tap()
        XCTAssertEqual(app.staticTexts["fakeMail.subject"].waitToAppear().label, "Jugador reportado en el ranking · Contrarreloj")
    }
}
