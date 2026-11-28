import XCTest

/// Launches the app with fakes (no network, no Firebase) and the given options.
@MainActor
func launchApp(_ extra: [String] = [], consent: String = "rejected") -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-uiTesting", "-consent", consent] + extra
    app.launch()
    return app
}

extension XCUIApplication {
    /// A tab of the tab bar (a tab bar on iPhone, a top bar or sidebar on iPad).
    func tab(_ name: String) -> XCUIElement {
        let inTabBar = tabBars.buttons[name]
        return inTabBar.exists ? inTabBar : buttons.matching(identifier: name).firstMatch
    }
}

extension XCUIElement {
    @discardableResult
    func waitToAppear(_ timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(waitForExistence(timeout: timeout), "\(self) did not appear", file: file, line: line)
        return self
    }
}

extension XCUIApplication {
    /// Plays the 6-question "tiny" arcade game to the end, answering right or wrong every time.
    func playTinyGame(right: Bool) {
        buttons["home.playArcade"].waitToAppear().tap()
        otherElements["game.screen"].waitToAppear()
        let label = right ? "Correcta" : "Falsa uno"
        for index in 0..<6 {
            let question = staticTexts["question.text"].waitToAppear()
            let previous = question.label
            buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch.waitToAppear().tap()
            if index < 5 {
                let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", previous), object: question)
                XCTAssertEqual(XCTWaiter().wait(for: [changed], timeout: 5), .completed)
            }
        }
        otherElements["report.screen"].waitToAppear()
    }
}
