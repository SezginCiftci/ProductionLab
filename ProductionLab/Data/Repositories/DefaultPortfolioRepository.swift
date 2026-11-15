import Foundation
import OSLog
import SwiftData

/// Portföy verisini Mock API'den çeker ve SwiftData'da saklar.
@MainActor
final class DefaultPortfolioRepository: PortfolioRepository {
    private let apiClient: PortfolioAPIClient
    private let context: ModelContext

    init(apiClient: PortfolioAPIClient, context: ModelContext) {
        self.apiClient = apiClient
        self.context = context
    }

    func cachedPortfolio() throws -> Portfolio? {
        guard let portfolio = try context.fetch(FetchDescriptor<PortfolioEntity>()).first else {
            return nil
        }
        let holdings = try context.fetch(FetchDescriptor<HoldingEntity>(sortBy: [SortDescriptor(\.symbol)]))
        return portfolio.toDomain(holdings: holdings.map { $0.toDomain() })
    }

    /// Akış: fetch → decode → DTO→Domain → SwiftData'ya kaydet.
    /// Hata veya iptal olursa hiçbir şey kaydedilmez, eski veri olduğu gibi kalır.
    func refreshPortfolio() async throws -> Portfolio {
        let portfolioDTO = try await apiClient.fetchPortfolio()
        let holdingDTOs = try await apiClient.fetchHoldings()

        // Bu noktada istek iptal edildiyse kaydetmeden çık.
        try Task.checkCancellation()

        let portfolio = portfolioDTO.toDomain(holdings: holdingDTOs.map { $0.toDomain() })
        try save(portfolio)
        AppLogger.persistence.info("Refresh kaydedildi: \(portfolio.holdings.count) varlık")

        return try cachedPortfolio() ?? portfolio
    }

    func lastRefreshDate() -> Date? {
        let metadata = try? context.fetch(FetchDescriptor<SyncMetadataEntity>()).first
        return metadata?.lastSyncedAt
    }

    /// Aynı id'ye sahip kayıt varsa günceller, yoksa ekler (upsert). Böylece kopya oluşmaz.
    private func save(_ portfolio: Portfolio) throws {
        let now = Date()

        if let entity = try context.fetch(FetchDescriptor<PortfolioEntity>()).first(where: { $0.id == portfolio.id }) {
            entity.name = portfolio.name
            entity.currencyCode = portfolio.currencyCode
            entity.updatedAt = now
        } else {
            context.insert(PortfolioEntity(portfolio: portfolio, date: now))
        }

        // Mevcut kayıtları id → entity sözlüğüne koyuyoruz; 5.000 kayıtta bile arama hızlı olur.
        var existingHoldings: [UUID: HoldingEntity] = [:]
        for entity in try context.fetch(FetchDescriptor<HoldingEntity>()) {
            existingHoldings[entity.id] = entity
        }
        for holding in portfolio.holdings {
            if let entity = existingHoldings[holding.id] {
                entity.update(from: holding)
            } else {
                context.insert(HoldingEntity(holding: holding))
            }
        }

        if let metadata = try context.fetch(FetchDescriptor<SyncMetadataEntity>()).first {
            metadata.syncStatus = "synced"
            metadata.lastSyncedAt = now
        } else {
            context.insert(SyncMetadataEntity(resourceType: "portfolio", syncStatus: "synced", lastSyncedAt: now))
        }

        // Ya hepsi kaydedilir ya hiçbiri: save başarısız olursa değişiklikler geri alınır.
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
