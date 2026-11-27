import XCTest

@MainActor
final class SettingsTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func openSettings(_ extra: [String] = [], consent: String = "rejected") -> XCUIApplication {
        let app = launchApp(extra, consent: consent)
        app.tab("Ajustes").waitToAppear().tap()
        return app
    }

    /// Lists only create the rows on screen: scroll until the element exists and can be tapped.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < 8 {
            if swipes == 0 && element.waitForExistence(timeout: 2) && element.isHittable { break }
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.exists, "\(element) not found")
        return element
    }

    func testAnalyticsToggleReflectsConsent() {
        let app = openSettings()
        let toggle = reveal(app.switches["settings.analytics"], in: app)
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.switches.firstMatch.tap()
        XCTAssertEqual(app.switches["settings.analytics"].value as? String, "1")
    }

    func testSignOutReturnsToSignedOutHome() {
        let app = openSettings(["-fakeUser", "google"])
        app.buttons["settings.signOut"].waitToAppear().tap()
        app.tab("Jugar").tap()
        app.buttons["home.signIn"].waitToAppear()
    }

    func testDeleteAccountExplainsConfirmsAndSignsOut() {
        let app = openSettings(["-fakeUser", "apple"])
        app.buttons["settings.deleteAccount"].waitToAppear().tap()
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Se borrarán tu cuenta y tus puntuaciones'")).firstMatch.waitToAppear()
        app.buttons["deleteAccount.confirm"].tap()
        app.alerts.buttons["Eliminar"].waitToAppear().tap()
        app.staticTexts["Tu cuenta se ha eliminado."].waitToAppear()
        app.tab("Jugar").tap()
        app.buttons["home.signIn"].waitToAppear()
    }

    func testDeleteAccountErrorAllowsRetry() {
        let app = openSettings(["-fakeUser", "google", "-rankingFake", "failing"])
        app.buttons["settings.deleteAccount"].waitToAppear().tap()
        app.buttons["deleteAccount.confirm"].waitToAppear().tap()
        app.alerts.buttons["Eliminar"].waitToAppear().tap()
        app.staticTexts["No se ha podido eliminar tu cuenta. Inténtalo de nuevo."].waitToAppear()
        XCTAssertTrue(app.buttons["Reintentar"].exists)
    }

    func testContactReasonsOpenMailWithSubject() {
        let app = openSettings()
        reveal(app.buttons["settings.contact"], in: app).tap()
        app.buttons["Una sugerencia"].waitToAppear().tap()
        XCTAssertEqual(app.staticTexts["fakeMail.subject"].waitToAppear().label, "Sugerencia · Contrarreloj")
    }

    func testSocialLinksAndLegalScreens() {
        let app = openSettings()
        _ = reveal(app.descendants(matching: .any)["social.instagram"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["social.x"].exists)
        reveal(app.buttons["settings.privacy"], in: app).tap()
        app.staticTexts["Política de privacidad"].waitToAppear()
        app.navigationBars.buttons.firstMatch.tap()
        reveal(app.buttons["settings.legal"], in: app).tap()
        app.staticTexts["Aviso legal"].waitToAppear()
    }

    func testUnhidePlayer() {
        let app = launchApp(["-rankingFake", "seeded"])
        app.tab("Ranking").waitToAppear().tap()
        app.buttons["ranking.more.u2"].waitToAppear().tap()
        app.buttons["Ocultar jugador"].waitToAppear().tap()
        app.tab("Ajustes").tap()
        reveal(app.buttons["settings.hidden"], in: app).tap()
        app.staticTexts["Luis"].waitToAppear()
        app.buttons["Mostrar"].tap()
        app.staticTexts["No has ocultado a ningún jugador."].waitToAppear()
    }
}
