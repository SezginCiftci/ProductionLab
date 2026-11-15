import Foundation
import Testing
@testable import ProductionLab

@MainActor
struct DashboardViewModelTests {
    let repository = FakePortfolioRepository(cached: makePortfolio(totalValue: 90_000))
    var viewModel: DashboardViewModel {
        DashboardViewModel(portfolioRepository: repository, transactionRepository: FakeTransactionRepository())
    }

    @Test func startsIdle() {
        let viewModel = viewModel
        guard case .idle = viewModel.state else {
            Issue.record("Başlangıç durumu .idle olmalıydı")
            return
        }
        #expect(!viewModel.isRefreshing)
        #expect(viewModel.lastRefreshDate == nil)
    }

    @Test func withoutCacheStateIsLoading() {
        repository.cached = nil
        let viewModel = viewModel
        viewModel.loadCache()
        guard case .loading = viewModel.state else {
            Issue.record("Önbellek yokken durum .loading olmalıydı")
            return
        }
    }

    @Test func recentTransactionsAreLimitedToFive() {
        let transactions = FakeTransactionRepository()
        transactions.items = (0..<8).map { _ in
            Transaction(id: UUID(), portfolioID: testPortfolioID, holdingID: nil, type: .buy,
                        symbol: "X", quantity: 1, price: 1, createdAt: Date())
        }
        let viewModel = DashboardViewModel(portfolioRepository: repository, transactionRepository: transactions)
        viewModel.loadCache()
        #expect(viewModel.content?.recentTransactions.count == 5)
    }

    @Test func cacheIsShownImmediately() {
        let viewModel = viewModel
        viewModel.loadCache()
        #expect(viewModel.content?.summary.totalValue == 90_000)
    }

    @Test func successfulRefreshUpdatesState() async {
        repository.responses = [(.success(makePortfolio(totalValue: 120_000)), .zero)]
        let viewModel = viewModel

        viewModel.refresh()
        #expect(viewModel.isRefreshing)
        await viewModel.refreshTask?.value

        #expect(viewModel.content?.summary.totalValue == 120_000)
        #expect(!viewModel.isRefreshing)
    }

    @Test func errorKeepsCacheAndShowsMessage() async {
        repository.responses = [(.failure(AppError.server(statusCode: 503)), .zero)]
        let viewModel = viewModel
        viewModel.loadCache()

        viewModel.refresh()
        await viewModel.refreshTask?.value

        #expect(viewModel.content?.summary.totalValue == 90_000)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func errorWithoutCacheShowsFailedState() async {
        repository.cached = nil
        repository.responses = [(.failure(AppError.server(statusCode: 503)), .zero)]
        let viewModel = viewModel

        viewModel.refresh()
        await viewModel.refreshTask?.value

        guard case .failed = viewModel.state else {
            Issue.record("State .failed olmalıydı")
            return
        }
    }

    /// A isteği yavaş (100.000), B hızlı (120.000) ve sonra başlıyor. Sonuç B olmalı.
    @Test func staleResponseCannotOverwriteNewerResult() async {
        repository.responses = [
            (.success(makePortfolio(totalValue: 100_000)), .milliseconds(500)), // A
            (.success(makePortfolio(totalValue: 120_000)), .milliseconds(10)),  // B
        ]
        let viewModel = viewModel
        viewModel.loadCache()

        viewModel.refresh()                      // A başlar
        let requestA = viewModel.refreshTask
        viewModel.refresh()                      // B başlar, A iptal edilir

        await viewModel.refreshTask?.value
        await requestA?.value

        #expect(viewModel.content?.summary.totalValue == 120_000)
    }

    @Test func cancelKeepsCacheWithoutError() async {
        repository.responses = [(.success(makePortfolio(totalValue: 100_000)), .seconds(30))]
        let viewModel = viewModel
        viewModel.loadCache()

        viewModel.refresh()
        viewModel.cancelRefresh()
        await viewModel.refreshTask?.value

        #expect(viewModel.content?.summary.totalValue == 90_000)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isRefreshing)
    }

    @Test func onAppearRefreshesOnlyOnce() async {
        repository.responses = [(.success(makePortfolio(totalValue: 120_000)), .zero)]
        let viewModel = viewModel

        viewModel.onAppear()
        await viewModel.refreshTask?.value
        viewModel.onAppear() // ikinci kez açılış: yenileme yapılmamalı

        #expect(repository.refreshCallCount == 1)
    }
}
