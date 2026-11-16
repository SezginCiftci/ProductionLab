import XCTest
@testable import ProductionLab

/// XCTest'in `measure` API'si ile performans ölçümü (Swift Testing'de karşılığı yok).
/// Sonuçlar Xcode'un Report navigator'ında görünür; CPU lab'inde "önce/sonra" kıyası için kullanılır.
/// Not: Sabit bir süre sınırı (baseline) konmadı; ölçüm makineye göre değişir.
final class PerformanceTests: XCTestCase {
    private let holdings = PerformanceDataGenerator.holdings(count: 5_000, portfolioID: UUID())

    func testPortfolioSummaryWith5000Holdings() {
        measure {
            _ = PortfolioCalculator.summary(of: holdings)
        }
    }

    /// Debug derlemesinde de makul sürede bitmesi için 1.000 kayıt kullanılır.
    @MainActor
    func testHoldingsSortWith1000Holdings() {
        let holdings = Array(self.holdings.prefix(1_000))
        let portfolio = Portfolio(id: UUID(), name: "Perf", currencyCode: "USD", holdings: holdings)
        let viewModel = HoldingsViewModel(portfolioRepository: FakePortfolioRepository(cached: portfolio))
        viewModel.load()

        // Her turda sıralama değişir: piyasa değeri ↔ sembol. CPU lab'inde önce/sonra kıyası bu testle yapılır.
        measure {
            viewModel.sortOption = .marketValue
            _ = viewModel.visibleHoldings
            viewModel.sortOption = .symbolAscending
            _ = viewModel.visibleHoldings
        }
    }
}
