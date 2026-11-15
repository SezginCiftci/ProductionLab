import XCTest

final class ActivityAndDiagnosticsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// holdingID'si olmayan işlem güvenle açılır (crash lab'inin temiz sürümdeki regresyon testi).
    @MainActor
    func testTransactionWithoutHoldingOpensSafely() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()
        app.openTab("Activity")

        // İşlem listenin alt kısmında; List görünmeyen satırları oluşturmadığı için kaydırarak bulunur.
        let row = app.buttons["activity.row.LEGACY7"]
        XCTAssertTrue(app.scrollUntilVisible(row))
        row.tap()

        XCTAssertTrue(app.staticTexts["transactionDetail.noHolding"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["transactionDetail.amount"].exists)
    }

    @MainActor
    func testSellFilter() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()
        app.openTab("Activity")

        app.buttons["Sell"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sell '")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Buy '")).firstMatch.exists)
    }

    @MainActor
    func testSettingsShowsDebugConfiguration() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()
        app.openTab("Settings")

        XCTAssertTrue(app.staticTexts["settings.configuration"].label.contains("Debug"))
        XCTAssertTrue(app.staticTexts["settings.environment"].label.contains("Offline mock API"))
        XCTAssertTrue(app.buttons["settings.diagnostics"].exists)
    }

    /// Diagnostics'ten 1.000 kayıtlık sete geç, sonra normale dön.
    @MainActor
    func testSwitchingDataSet() {
        let app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()

        for (dataSet, expected) in [("1000", "1000"), ("20", "20")] {
            app.openTab("Settings")
            app.buttons["settings.diagnostics"].tap()
            app.buttons["diagnostics.dataSet.\(dataSet)"].tap()

            // Seçimden sonra sekmeler yeniden kurulur ve Dashboard açılır.
            let count = app.staticTexts["dashboard.holdingCount"]
            XCTAssertTrue(count.waitForExistence(timeout: 10))
            XCTAssertEqual(count.digits, expected)
        }
    }
}
