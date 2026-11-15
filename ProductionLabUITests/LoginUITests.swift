import XCTest

final class LoginUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLoginAndLogout() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()

        app.openTab("Settings")
        app.buttons["settings.logout"].tap()

        XCTAssertTrue(app.textFields["login.username"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testInvalidLoginShowsError() {
        let app = XCUIApplication.launchForTesting()
        app.signIn(password: "wrong")

        XCTAssertTrue(app.staticTexts["login.error"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["dashboard.totalValue"].exists)
    }

    @MainActor
    func testSubmitIsDisabledWithEmptyFields() {
        let app = XCUIApplication.launchForTesting()
        XCTAssertTrue(app.buttons["login.submit"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["login.submit"].isEnabled)
    }

    /// Giriş → kapat → aç: Keychain'deki token sayesinde Login atlanır. Çıkıştan sonra tekrar Login gelir.
    @MainActor
    func testSessionIsRestoredAfterRelaunch() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()
        app.terminate()

        let relaunched = XCUIApplication.launchForTesting(resetSession: false)
        XCTAssertTrue(relaunched.staticTexts["dashboard.totalValue"].waitForExistence(timeout: 10))

        relaunched.openTab("Settings")
        relaunched.buttons["settings.logout"].tap()
        XCTAssertTrue(relaunched.textFields["login.username"].waitForExistence(timeout: 5))
        relaunched.terminate()

        let afterLogout = XCUIApplication.launchForTesting(resetSession: false)
        XCTAssertTrue(afterLogout.textFields["login.username"].waitForExistence(timeout: 10))
    }
}
