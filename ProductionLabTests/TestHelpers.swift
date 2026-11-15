import Foundation
@testable import ProductionLab

// Testlerde kullanılan örnek veriler ve fake repository'ler.
// Testler internete, gerçek Keychain'e veya diskteki veritabanına dokunmaz.

let testPortfolioID = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!

func makeHolding(symbol: String, name: String = "Test", quantity: Double,
                 averageCost: Double, currentPrice: Double) -> Holding {
    Holding(id: UUID(), portfolioID: testPortfolioID, symbol: symbol, name: name,
            quantity: quantity, averageCost: averageCost, currentPrice: currentPrice,
            updatedAt: Date())
}

/// Toplam değeri tam olarak `totalValue` olan tek varlıklı portföy.
func makePortfolio(totalValue: Double) -> Portfolio {
    let holding = makeHolding(symbol: "DEMO1", quantity: 100, averageCost: 900, currentPrice: totalValue / 100)
    return Portfolio(id: testPortfolioID, name: "Test", currencyCode: "USD", holdings: [holding])
}

/// Her refresh çağrısında sıradaki cevabı, verilen süre kadar bekleyip döndürür.
@MainActor
final class FakePortfolioRepository: PortfolioRepository {
    var cached: Portfolio?
    /// Sırayla dönecek cevaplar: (sonuç, bekleme süresi)
    var responses: [(result: Result<Portfolio, Error>, delay: Duration)] = []
    private(set) var refreshCallCount = 0

    init(cached: Portfolio? = nil) {
        self.cached = cached
    }

    func cachedPortfolio() throws -> Portfolio? { cached }

    func refreshPortfolio() async throws -> Portfolio {
        let response = responses[refreshCallCount]
        refreshCallCount += 1
        try await Task.sleep(for: response.delay) // iptal edilirse CancellationError fırlatır
        return try response.result.get()
    }

    func lastRefreshDate() -> Date? { nil }
}

@MainActor
final class FakeTransactionRepository: TransactionRepository {
    var items: [Transaction] = []

    func transactions() throws -> [Transaction] { items }
    func recentTransactions(limit: Int) throws -> [Transaction] { Array(items.prefix(limit)) }
}

/// Her işlemde hata fırlatan storage: Keychain'in bozulduğu durumu taklit eder.
final class FailingSecureStorage: SecureStorage {
    struct Failure: Error {}

    func save(_ data: Data, for key: String) throws { throw Failure() }
    func read(for key: String) throws -> Data? { throw Failure() }
    func delete(for key: String) throws { throw Failure() }
}
