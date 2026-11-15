import XCTest

final class HoldingsUITests: XCTestCase {
    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
        app.signInAndWaitForDashboard()
        app.openTab("Holdings")
        XCTAssertTrue(app.staticTexts["holdings.count"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testShowsAllHoldings() {
        XCTAssertEqual(app.staticTexts["holdings.count"].digits, "2020") // "20 / 20 varlık"
    }

    @MainActor
    func testSearchByNameIsCaseInsensitive() {
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("robotics") // "Mock Robotics" → DEMO11

        XCTAssertTrue(app.buttons["holdings.row.DEMO11"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["holdings.row.DEMO1"].exists)
        XCTAssertEqual(app.staticTexts["holdings.count"].digits, "120") // "1 / 20 varlık"
    }

    @MainActor
    func testSearchWithoutResultsShowsEmptyState() {
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("zzz")

        XCTAssertTrue(app.descendants(matching: .any)["holdings.empty"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSortSymbolDescending() {
        // Varsayılan: Sembol A–Z → DEMO1 en üstte.
        XCTAssertTrue(isAbove("DEMO1", "DEMO2"))

        app.buttons["holdings.sort"].tap()
        app.buttons["Sembol Z–A"].tap()

        // Doğal sıralamada DEMO20 en büyük sembol.
        let top = app.buttons["holdings.row.DEMO20"]
        XCTAssertTrue(top.waitForExistence(timeout: 5))
        XCTAssertTrue(isAbove("DEMO20", "DEMO19"))
    }

    @MainActor
    func testOpenDetail() {
        app.buttons["holdings.row.DEMO1"].tap()

        let marketValue = app.staticTexts["holdingDetail.marketValue"]
        XCTAssertTrue(marketValue.waitForExistence(timeout: 5))
        XCTAssertEqual(marketValue.digits, "203625") // 15 × 135,75 = 2.036,25
        XCTAssertTrue(app.navigationBars["DEMO1"].exists)
    }

    /// İki satırın ekrandaki dikey sırası.
    @MainActor
    private func isAbove(_ first: String, _ second: String) -> Bool {
        let a = app.buttons["holdings.row.\(first)"]
        let b = app.buttons["holdings.row.\(second)"]
        guard a.waitForExistence(timeout: 5), b.waitForExistence(timeout: 5) else { return false }
        return a.frame.minY < b.frame.minY
    }
}
