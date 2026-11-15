import Foundation

// Repository sözleşmeleri. ViewModel'ler yalnızca bu protokolleri bilir;
// testlerde gerçek implementasyon yerine fake sınıflar verilir.
// Hepsi @MainActor: SwiftData'nın mainContext'i ile aynı yerde çalışırlar.

@MainActor
protocol PortfolioRepository {
    /// SwiftData'daki kayıtlı portföy (ağa gitmeden).
    func cachedPortfolio() throws -> Portfolio?

    /// Mock API'den yeni veriyi çeker ve SwiftData'ya kaydeder.
    func refreshPortfolio() async throws -> Portfolio

    /// Son başarılı yenileme zamanı. Hiç yenilenmediyse nil.
    func lastRefreshDate() -> Date?
}

@MainActor
protocol TransactionRepository {
    /// Tüm işlemler, en yeni en üstte.
    func transactions() throws -> [Transaction]

    /// En yeni `limit` adet işlem.
    func recentTransactions(limit: Int) throws -> [Transaction]
}
