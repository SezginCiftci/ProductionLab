import Foundation
import Testing
@testable import ProductionLab

@MainActor
struct HoldingsViewModelTests {
    let viewModel: HoldingsViewModel

    init() {
        let holdings = [
            makeHolding(symbol: "BETA", name: "Sample Energy", quantity: 10, averageCost: 10, currentPrice: 30),     // 300, +%200
            makeHolding(symbol: "ALPHA", name: "Demo Technology", quantity: 1, averageCost: 400, currentPrice: 500), // 500, +%25
            makeHolding(symbol: "GAMMA", name: "Mock Logistics", quantity: 2, averageCost: 50, currentPrice: 40),    // 80, -%20
        ]
        let repository = FakePortfolioRepository(
            cached: Portfolio(id: testPortfolioID, name: "Test", currencyCode: "EUR", holdings: holdings))
        viewModel = HoldingsViewModel(portfolioRepository: repository)
        viewModel.load()
    }

    var symbols: [String] { viewModel.visibleHoldings.map(\.symbol) }

    @Test func loadReadsCache() {
        #expect(viewModel.holdings.count == 3)
        #expect(viewModel.currencyCode == "EUR")
        #expect(viewModel.errorMessage == nil)
    }

    @Test func sorting() {
        #expect(symbols == ["ALPHA", "BETA", "GAMMA"])
        viewModel.sortOption = .symbolDescending
        #expect(symbols == ["GAMMA", "BETA", "ALPHA"])
        viewModel.sortOption = .marketValue
        #expect(symbols == ["ALPHA", "BETA", "GAMMA"])
        viewModel.sortOption = .profitLossPercent
        #expect(symbols == ["BETA", "ALPHA", "GAMMA"])
    }

    @Test func symbolSortIsNatural() {
        let repository = FakePortfolioRepository(cached: Portfolio(
            id: testPortfolioID, name: "Test", currencyCode: "USD",
            holdings: ["DEMO10", "DEMO2", "DEMO1"].map { makeHolding(symbol: $0, quantity: 1, averageCost: 1, currentPrice: 1) }))
        let viewModel = HoldingsViewModel(portfolioRepository: repository)
        viewModel.load()
        #expect(viewModel.visibleHoldings.map(\.symbol) == ["DEMO1", "DEMO2", "DEMO10"]) // DEMO10, DEMO2'den sonra gelir
    }

    @Test func searchIsCaseInsensitiveOnSymbolAndName() {
        viewModel.searchText = "gam"
        #expect(symbols == ["GAMMA"])
        viewModel.searchText = "TECHNOLOGY"
        #expect(symbols == ["ALPHA"])
        viewModel.searchText = "yok-boyle-bir-sey"
        #expect(symbols.isEmpty)
        #expect(viewModel.holdings.count == 3) // toplam sayı değişmez
        viewModel.searchText = ""
        #expect(symbols.count == 3)
    }

    @Test func searchAndSortWorkTogether() {
        viewModel.searchText = "a" // ALPHA, BETA, GAMMA hepsinde "a" var
        viewModel.sortOption = .symbolDescending
        #expect(symbols == ["GAMMA", "BETA", "ALPHA"])
    }
}

@MainActor
struct ActivityViewModelTests {
    func makeTransaction(_ type: TransactionType, holdingID: UUID?) -> Transaction {
        Transaction(id: UUID(), portfolioID: testPortfolioID, holdingID: holdingID, type: type,
                    symbol: "X", quantity: 2, price: 5, createdAt: Date())
    }

    @Test func filter() {
        let repository = FakeTransactionRepository()
        repository.items = [makeTransaction(.buy, holdingID: UUID()), makeTransaction(.sell, holdingID: nil), makeTransaction(.buy, holdingID: nil)]
        let viewModel = ActivityViewModel(transactionRepository: repository)
        viewModel.load()

        #expect(viewModel.visibleTransactions.count == 3)
        viewModel.filter = .buy
        #expect(viewModel.visibleTransactions.allSatisfy { $0.type == .buy })
        #expect(viewModel.visibleTransactions.count == 2)
        viewModel.filter = .sell
        #expect(viewModel.visibleTransactions.count == 1)
    }

    @Test func amountIsQuantityTimesPrice() {
        #expect(makeTransaction(.buy, holdingID: nil).amount == 10)
    }
}
