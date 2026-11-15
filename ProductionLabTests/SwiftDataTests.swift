import Foundation
import SwiftData
import Testing
@testable import ProductionLab

/// Gerçek repository'leri bellekte çalışan bir SwiftData veritabanıyla test eder.
@MainActor
struct SwiftDataTests {
    let context: ModelContext

    init() throws {
        let container = try ModelContainer(
            for: PortfolioEntity.self, HoldingEntity.self, TransactionEntity.self, SyncMetadataEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        try DataSeeder.seedIfNeeded(context: context)
    }

    func makeRepository(_ scenario: MockScenario) async -> DefaultPortfolioRepository {
        let controller = MockScenarioController()
        await controller.setScenario(scenario)
        let client = MockPortfolioAPIClient(scenarioController: controller, delay: .zero, slowDelay: .zero)
        return DefaultPortfolioRepository(apiClient: client, context: context)
    }

    func holdingCount() throws -> Int {
        try context.fetchCount(FetchDescriptor<HoldingEntity>())
    }

    @Test func firstSeedInsertsDemoData() throws {
        #expect(try context.fetchCount(FetchDescriptor<PortfolioEntity>()) == 1)
        #expect(try holdingCount() == 20)
        #expect(try context.fetchCount(FetchDescriptor<TransactionEntity>()) == 40)
    }

    @Test func seedingAgainDoesNotDuplicate() throws {
        try DataSeeder.seedIfNeeded(context: context)
        #expect(try context.fetchCount(FetchDescriptor<PortfolioEntity>()) == 1)
        #expect(try holdingCount() == 20)
    }

    @Test func cachedPortfolioMapsEntitiesToDomain() async throws {
        let repository = await makeRepository(.success)
        let portfolio = try #require(try repository.cachedPortfolio())
        let demo1 = try #require(portfolio.holdings.first { $0.symbol == "DEMO1" })
        #expect(demo1.quantity == 15)
        #expect(demo1.averageCost == 120.5)
        #expect(demo1.currentPrice == 135.75)
    }

    @Test func successfulRefreshDoesNotCreateDuplicates() async throws {
        let repository = await makeRepository(.success)
        #expect(repository.lastRefreshDate() == nil)

        _ = try await repository.refreshPortfolio()
        _ = try await repository.refreshPortfolio()

        #expect(try holdingCount() == 20)
        #expect(repository.lastRefreshDate() != nil)
    }

    @Test(arguments: [MockScenario.serverError, MockScenario.invalidJSON])
    func failedRefreshKeepsCache(scenario: MockScenario) async throws {
        let repository = await makeRepository(scenario)
        let before = try repository.cachedPortfolio()

        await #expect(throws: (any Error).self) {
            try await repository.refreshPortfolio()
        }

        #expect(try repository.cachedPortfolio() == before)
        #expect(repository.lastRefreshDate() == nil)
    }

    /// Refresh aynı UUID'li kaydı günceller (holdings_stale_b'de DEMO1 fiyatı 1.200).
    @Test func refreshUpdatesExistingRecord() async throws {
        let client = MockPortfolioAPIClient(scenarioController: MockScenarioController(), delay: .zero,
                                            holdingsFileName: "holdings_stale_b")
        let repository = DefaultPortfolioRepository(apiClient: client, context: context)

        let refreshed = try await repository.refreshPortfolio()

        let demo1 = try #require(refreshed.holdings.first { $0.symbol == "DEMO1" })
        #expect(demo1.currentPrice == 1_200)
        #expect(try holdingCount() == 20) // güncellendi, yeni kayıt eklenmedi
    }

    @Test func cancelledRefreshKeepsCache() async throws {
        let client = MockPortfolioAPIClient(scenarioController: MockScenarioController(), delay: .seconds(30))
        let repository = DefaultPortfolioRepository(apiClient: client, context: context)
        let before = try repository.cachedPortfolio()

        let task = Task { try await repository.refreshPortfolio() }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try repository.cachedPortfolio() == before)
        #expect(repository.lastRefreshDate() == nil)
    }

    @Test func transactionsAreNewestFirst() throws {
        let transactions = try DefaultTransactionRepository(context: context).transactions()
        #expect(transactions.count == 40)
        #expect(transactions.first!.createdAt >= transactions.last!.createdAt)
        #expect(transactions.contains { $0.holdingID == nil }) // crash lab'in ön koşulu
    }
}
