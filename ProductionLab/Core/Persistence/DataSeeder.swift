import Foundation
import OSLog
import SwiftData

/// İlk açılışta JSON dosyalarındaki demo verisini (1 portföy, 20 varlık, 40 işlem) SwiftData'ya ekler.
enum DataSeeder {
    /// Veritabanında zaten portföy varsa hiçbir şey yapmaz; bu yüzden tekrar çağrılması güvenlidir.
    /// `generatedHoldingCount` verilirse holdings.json yerine PerformanceDataGenerator kullanılır.
    @MainActor
    static func seedIfNeeded(context: ModelContext, generatedHoldingCount: Int? = nil) throws {
        let existingCount = try context.fetchCount(FetchDescriptor<PortfolioEntity>())
        if existingCount > 0 {
            AppLogger.persistence.info("Seed atlandı: veri zaten var")
            return
        }

        let decoder = MockData.makeDecoder()
        let portfolio = try decoder.decode(PortfolioDTO.self, from: MockData.load("portfolio"))
        let holdings: [HoldingDTO]
        if let count = generatedHoldingCount {
            holdings = PerformanceDataGenerator.holdings(count: count, portfolioID: portfolio.id).map { HoldingDTO(holding: $0) }
        } else {
            holdings = try decoder.decode([HoldingDTO].self, from: MockData.load("holdings"))
        }
        let transactions = try decoder.decode([TransactionDTO].self, from: MockData.load("transactions"))

        // DTO → Domain → Entity
        let now = Date()
        context.insert(PortfolioEntity(portfolio: portfolio.toDomain(holdings: []), date: now))
        for holding in holdings {
            context.insert(HoldingEntity(holding: holding.toDomain()))
        }
        for transaction in transactions {
            context.insert(TransactionEntity(transaction: transaction.toDomain()))
        }
        try context.save()

        AppLogger.persistence.notice("Seed eklendi: \(holdings.count) varlık, \(transactions.count) işlem")
    }
}
