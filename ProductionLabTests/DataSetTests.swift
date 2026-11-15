import Foundation
import Testing
@testable import ProductionLab

/// Diagnostics'teki veri seti değişimini gerçek container ile (bellekte) test eder.
@MainActor
struct DataSetTests {
    let container = AppDependencyContainer(inMemory: true, secureStorage: InMemorySecureStorage())

    func holdingCount() throws -> Int {
        try container.portfolioRepository.cachedPortfolio()?.holdings.count ?? 0
    }

    @Test func startsWithStandardDataSet() throws {
        #expect(container.dataSet == .standard)
        #expect(try holdingCount() == 20)
    }

    @Test(arguments: [DataSet.large, DataSet.huge])
    func switchingToPerformanceDataSetLoadsGeneratedHoldings(dataSet: DataSet) throws {
        try container.switchDataSet(to: dataSet)
        #expect(container.dataSet == dataSet)
        #expect(try holdingCount() == dataSet.rawValue)
        #expect(try container.transactionRepository.transactions().count == 40)
    }

    @Test func switchingBackRestoresNormalDataUntouched() throws {
        let before = try container.portfolioRepository.cachedPortfolio()

        try container.switchDataSet(to: .huge)
        try container.switchDataSet(to: .standard)

        #expect(try container.portfolioRepository.cachedPortfolio() == before)
    }

    @Test(arguments: [1_000, 5_000])
    func generatorIsDeterministic(count: Int) {
        let first = PerformanceDataGenerator.holdings(count: count, portfolioID: testPortfolioID)
        let second = PerformanceDataGenerator.holdings(count: count, portfolioID: testPortfolioID)
        #expect(first.count == count)
        #expect(first == second)
        #expect(Set(first.map(\.id)).count == count) // UUID'ler benzersiz
    }

    @Test func refreshInPerformanceDataSetKeepsSameRecords() async throws {
        try container.switchDataSet(to: .large)
        await container.scenarioController.setScenario(.success)

        let refreshed = try await container.portfolioRepository.refreshPortfolio()

        #expect(refreshed.holdings.count == 1_000) // aynı UUID'ler güncellendi, kopya yok
    }
}
