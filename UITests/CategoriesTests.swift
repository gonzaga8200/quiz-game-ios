import XCTest

@MainActor
final class CategoriesTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func openScience(_ app: XCUIApplication) {
        app.tab("Categorías").waitToAppear().tap()
        let card = app.buttons["categories.card.ciencias"].waitToAppear()
        var swipes = 0
        while !card.isHittable && swipes < 5 { app.swipeUp(); swipes += 1 }
        card.tap()
        app.staticTexts["Preguntas de ciencias con respuestas"].waitToAppear()
    }

    func testCategoryDetailShowsTwentyQuestionsWithAnswers() {
        let app = launchApp()
        openScience(app)
        let items = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'category.item.'"))
        XCTAssertEqual(items.count, 20)
        XCTAssertTrue(items.firstMatch.label.contains("Respuesta:"))
    }

    func testPlayCategoryStartsArcadeOfThatCategory() {
        let app = launchApp(["-seed", "5"])
        openScience(app)
        app.buttons["category.play"].firstMatch.tap()
        app.otherElements["game.screen"].waitToAppear()
        for _ in 0..<3 {
            XCTAssertTrue(app.staticTexts["question.category"].waitToAppear().label == "Ciencias")
            let previous = app.staticTexts["question.text"].label
            app.buttons["skip"].tap()
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", previous),
                                                    object: app.staticTexts["question.text"])
            XCTAssertEqual(XCTWaiter().wait(for: [changed], timeout: 5), .completed)
        }
    }

    func testPlayAllStartsMixedArcade() {
        let app = launchApp()
        app.tab("Categorías").waitToAppear().tap()
        app.buttons["categories.playAll"].waitToAppear().tap()
        app.otherElements["game.screen"].waitToAppear()
    }

    func testCategoriesShowLoadingWhileTheBankLoads() {
        let app = launchApp(["-bank", "slow"])
        app.tab("Categorías").waitToAppear().tap()
        app.staticTexts["Cargando preguntas…"].waitToAppear(2)
        let science = app.buttons["categories.card.ciencias"]
        if science.exists {
            XCTAssertFalse(science.label.contains("0 preguntas en el juego"), "no count before the bank loads")
        }
        let loaded = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS '2 preguntas en el juego'"),
                                               object: science)
        XCTAssertEqual(XCTWaiter().wait(for: [loaded], timeout: 10), .completed)
    }
}
