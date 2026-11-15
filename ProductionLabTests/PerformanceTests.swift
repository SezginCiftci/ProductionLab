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

    @MainActor
    func testHoldingsSearchAndSortWith5000Holdings() {
        let portfolio = Portfolio(id: UUID(), name: "Perf", currencyCode: "USD", holdings: holdings)
        let viewModel = HoldingsViewModel(portfolioRepository: FakePortfolioRepository(cached: portfolio))
        viewModel.load()
        viewModel.sortOption = .profitLossPercent

        measure {
            viewModel.searchText = "PERF1"
            _ = viewModel.visibleHoldings
        }
    }
}
