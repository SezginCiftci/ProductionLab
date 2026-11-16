import XCTest

final class DashboardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Açılışta önbellek görünür, otomatik refresh tamamlanınca "Son yenileme" dolar.
    @MainActor
    func testRefreshUpdatesLastRefreshDate() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()

        XCTAssertEqual(app.staticTexts["dashboard.holdingCount"].digits, "20")

        let lastRefresh = app.staticTexts["dashboard.lastRefresh"]
        XCTAssertTrue(lastRefresh.wait(until: "NOT (label CONTAINS 'Hiç')"), lastRefresh.label)

        // Elle yenileme: buton bir süre spinner'a dönüşür, sonra geri gelir. Hata mesajı çıkmaz.
        let refreshButton = app.buttons["dashboard.refresh"]
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["dashboard.refreshError"].exists)
    }

    /// Sunucu hatasında önbellek ekranda kalır ve ekranı kapatmayan bir hata mesajı görünür.
    @MainActor
    func testServerErrorKeepsCachedDataAndShowsMessage() {
        let app = XCUIApplication.launchForTesting(scenario: "serverError")
        app.signInAndWaitForDashboard()

        let error = app.descendants(matching: .any)["dashboard.refreshError"]
        XCTAssertTrue(error.waitForExistence(timeout: 10))
        XCTAssertTrue(error.label.contains("503"), error.label)

        // Önbellek kaybolmadı.
        XCTAssertTrue(app.staticTexts["dashboard.totalValue"].exists)
        XCTAssertEqual(app.staticTexts["dashboard.holdingCount"].digits, "20")
        XCTAssertTrue(app.staticTexts["dashboard.lastRefresh"].label.contains("Hiç"))
    }

    /// Cancellation lab regresyonu: yavaş isteği "Vazgeç" ile iptal edince hata mesajı çıkmamalı,
    /// istek normalde biteceği süre (8 sn) geçtikten sonra da.
    @MainActor
    func testCancellingSlowRefreshShowsNoError() {
        let app = XCUIApplication.launchForTesting(scenario: "slowResponse")
        app.signInAndWaitForDashboard()

        let cancel = app.buttons["dashboard.cancelRefresh"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.tap()
        XCTAssertTrue(cancel.waitForNonExistence(timeout: 3))

        sleep(10) // iptal edilmeseydi istek bu sürede biterdi
        XCTAssertFalse(app.descendants(matching: .any)["dashboard.refreshError"].exists)
        XCTAssertTrue(app.staticTexts["dashboard.lastRefresh"].label.contains("Hiç"))
        XCTAssertEqual(app.staticTexts["dashboard.holdingCount"].digits, "20")
    }

    /// Diagnostics'ten senaryo değiştirip yenileme: hata → başarıya dönüş.
    @MainActor
    func testRecoversAfterSwitchingScenarioToSuccess() {
        let app = XCUIApplication.launchForTesting(scenario: "serverError")
        app.signInAndWaitForDashboard()
        XCTAssertTrue(app.descendants(matching: .any)["dashboard.refreshError"].waitForExistence(timeout: 10))

        app.openTab("Settings")
        app.buttons["settings.diagnostics"].tap()
        app.buttons["diagnostics.scenario.success"].tap()

        app.openTab("Dashboard")
        app.buttons["dashboard.refresh"].tap()

        let lastRefresh = app.staticTexts["dashboard.lastRefresh"]
        XCTAssertTrue(lastRefresh.wait(until: "NOT (label CONTAINS 'Hiç')"), lastRefresh.label)
        XCTAssertFalse(app.descendants(matching: .any)["dashboard.refreshError"].exists)
    }
}
