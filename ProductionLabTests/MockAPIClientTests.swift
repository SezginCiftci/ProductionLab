import Foundation
import Testing
@testable import ProductionLab

struct MockAPIClientTests {
    /// Bekleme süresi sıfır olan, verilen senaryoda çalışan client.
    func makeClient(_ scenario: MockScenario) async -> MockPortfolioAPIClient {
        let controller = MockScenarioController()
        await controller.setScenario(scenario)
        return MockPortfolioAPIClient(scenarioController: controller, delay: .zero, slowDelay: .zero)
    }

    @Test func success() async throws {
        let client = await makeClient(.success)
        let portfolio = try await client.fetchPortfolio()
        let holdings = try await client.fetchHoldings()
        #expect(portfolio.id == testPortfolioID)
        #expect(holdings.count == 20)
    }

    @Test func emptyResponse() async throws {
        let client = await makeClient(.emptyResponse)
        #expect(try await client.fetchHoldings().isEmpty)
    }

    @Test func serverError() async {
        let client = await makeClient(.serverError)
        await #expect(throws: AppError.server(statusCode: 503)) {
            try await client.fetchHoldings()
        }
    }

    @Test func invalidJSON() async {
        let client = await makeClient(.invalidJSON)
        await #expect(throws: DecodingError.self) {
            try await client.fetchHoldings()
        }
    }

    @Test func cancellationThrowsCancellationError() async {
        let client = MockPortfolioAPIClient(scenarioController: MockScenarioController(), delay: .seconds(10))
        let task = Task { try await client.fetchHoldings() }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func slowResponseStillSucceeds() async throws {
        let client = await makeClient(.slowResponse)
        #expect(try await client.fetchHoldings().count == 20)
    }

    /// İstek başladıktan sonra senaryo değişirse, o istek eski senaryoyla tamamlanır.
    @Test func scenarioChangeDoesNotAffectRunningRequest() async throws {
        let controller = MockScenarioController(scenario: .success)
        let client = MockPortfolioAPIClient(scenarioController: controller, delay: .milliseconds(300))

        let task = Task { try await client.fetchHoldings() }
        try await Task.sleep(for: .milliseconds(100)) // istek beklemedeyken
        await controller.setScenario(.serverError)

        #expect(try await task.value.count == 20)
    }

    @Test func staleResponseAlternatesBetweenAAndB() async throws {
        let client = await makeClient(.staleResponse)
        let first = try await client.fetchHoldings().map { $0.toDomain() }
        let second = try await client.fetchHoldings().map { $0.toDomain() }
        #expect(first.first?.currentPrice == 1_000)  // A
        #expect(second.first?.currentPrice == 1_200) // B
    }

    @Test func performanceDataSetReturnsGeneratedHoldings() async throws {
        var client = await makeClient(.success)
        client.generatedHoldingCount = 1_000
        #expect(try await client.fetchHoldings().count == 1_000)
    }

    @Test func staleFixturesHaveDifferentTotals() async throws {
        let controller = MockScenarioController()
        let clientA = MockPortfolioAPIClient(scenarioController: controller, delay: .zero, holdingsFileName: "holdings_stale_a")
        let clientB = MockPortfolioAPIClient(scenarioController: controller, delay: .zero, holdingsFileName: "holdings_stale_b")

        let holdingsA = try await clientA.fetchHoldings().map { $0.toDomain() }
        let holdingsB = try await clientB.fetchHoldings().map { $0.toDomain() }
        #expect(PortfolioCalculator.summary(of: holdingsA).totalValue == 100_000)
        #expect(PortfolioCalculator.summary(of: holdingsB).totalValue == 120_000)
    }
}
