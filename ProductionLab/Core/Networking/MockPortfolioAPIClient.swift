import Foundation
import OSLog

/// Gerçek bir sunucu yerine bundle'daki JSON'ları döndüren sahte API.
/// Bekleme, hata ve iptal davranışı gerçek bir ağ çağrısı gibidir.
struct MockPortfolioAPIClient: PortfolioAPIClient {
    let scenarioController: MockScenarioController
    /// Normal cevap süresi. Testlerde .zero verilerek hızlandırılır.
    var delay: Duration = .milliseconds(500)
    /// slowResponse senaryosundaki cevap süresi.
    var slowDelay: Duration = .seconds(8)
    /// Stale response lab'i için farklı bir holdings dosyası seçilebilir.
    var holdingsFileName = "holdings"
    /// Performans veri seti seçiliyse JSON yerine bu kadar üretilmiş varlık döner.
    var generatedHoldingCount: Int?

    func fetchPortfolio() async throws -> PortfolioDTO {
        let scenario = try await waitForResponse(operation: "fetchPortfolio")
        let fileName = scenario == .invalidJSON ? "holdings_invalid" : "portfolio"
        let data = try MockData.load(fileName)
        return try MockData.makeDecoder().decode(PortfolioDTO.self, from: data)
    }

    func fetchHoldings() async throws -> [HoldingDTO] {
        let scenario = try await waitForResponse(operation: "fetchHoldings")
        if scenario == .emptyResponse {
            return []
        }
        if scenario == .invalidJSON {
            return try MockData.makeDecoder().decode([HoldingDTO].self, from: MockData.load("holdings_invalid"))
        }
        if let count = generatedHoldingCount {
            let portfolio = try MockData.makeDecoder().decode(PortfolioDTO.self, from: MockData.load("portfolio"))
            return PerformanceDataGenerator.holdings(count: count, portfolioID: portfolio.id).map { HoldingDTO(holding: $0) }
        }
        let data = try MockData.load(holdingsFileName)
        return try MockData.makeDecoder().decode([HoldingDTO].self, from: data)
    }

    /// Ağ gecikmesini taklit eder ve isteğin başladığı andaki senaryoyu döndürür.
    private func waitForResponse(operation: String) async throws -> MockScenario {
        // Senaryo isteğin başında bir kez okunur. Sonradan değişirse bu isteği etkilemez.
        let scenario = await scenarioController.currentScenario()
        AppLogger.networking.info("\(operation, privacy: .public) başladı, senaryo: \(scenario.rawValue, privacy: .public)")

        // Task.sleep iptal edilirse hemen CancellationError fırlatır (Thread.sleep bunu yapamaz).
        try await Task.sleep(for: scenario == .slowResponse ? slowDelay : delay)

        if scenario == .serverError {
            AppLogger.networking.error("\(operation, privacy: .public) başarısız: HTTP 503")
            throw AppError.server(statusCode: 503)
        }
        return scenario
    }
}
