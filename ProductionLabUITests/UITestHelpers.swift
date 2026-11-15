import XCTest

// Tüm UI testlerinin ortak yardımcıları.
// Launch argümanları:
//   -ui-testing          → veriler bellekte (her açılışta temiz seed)
//   -reset-session       → açılışta Keychain'deki token silinir
//   -mock-scenario X     → mock API bu senaryoyla başlar (ör. serverError)

extension XCUIApplication {
    @MainActor
    static func launchForTesting(resetSession: Bool = true, scenario: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        if resetSession {
            app.launchArguments.append("-reset-session")
        }
        if let scenario {
            app.launchArguments += ["-mock-scenario", scenario]
        }
        app.launch()
        return app
    }

    /// Login ekranından demo hesabıyla giriş yapar.
    @MainActor
    func signIn(password: String = "demo123") {
        let username = textFields["login.username"]
        XCTAssertTrue(username.waitForExistence(timeout: 10))
        username.tap()
        username.typeText("demo")
        let passwordField = secureTextFields["login.password"]
        passwordField.tap()
        passwordField.typeText(password)
        buttons["login.submit"].tap()
    }

    /// Giriş yapıp Dashboard'un açılmasını bekler.
    @MainActor
    func signInAndWaitForDashboard() {
        signIn()
        XCTAssertTrue(staticTexts["dashboard.totalValue"].waitForExistence(timeout: 10))
    }

    @MainActor
    func openTab(_ name: String) {
        tabBars.buttons[name].tap()
    }

    /// Öğe görünür ve dokunulabilir olana kadar listeyi yukarı kaydırır.
    @MainActor
    func scrollUntilVisible(_ element: XCUIElement, maxSwipes: Int = 15) -> Bool {
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable {
                return true
            }
            swipeUp()
        }
        return element.exists && element.isHittable
    }
}

extension XCUIElement {
    /// Etiketteki rakamlar (ör. "Varlık sayısı, 1.000" → "1000"). Yerel ayardan bağımsız kıyas için.
    var digits: String { label.filter(\.isNumber) }

    /// Koşul sağlanana kadar bekler (ör. etiketin değişmesi).
    @MainActor
    func wait(until predicate: String, timeout: TimeInterval = 10) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
