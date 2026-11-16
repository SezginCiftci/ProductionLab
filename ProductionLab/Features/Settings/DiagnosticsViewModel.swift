import Foundation
import Observation
import OSLog

/// Yalnızca Debug derlemesinde açılan geliştirici ekranı:
/// mock API senaryosu ve performans veri seti seçimi.
@MainActor
@Observable
final class DiagnosticsViewModel {
    private(set) var scenario: MockScenario = .success
    private(set) var holdingCount = 0
    private(set) var transactionCount = 0
    private(set) var lastRefreshDate: Date?
    private(set) var errorMessage: String?
    private(set) var totalRequests = 0
    private(set) var isRunningStressTest = false

    private let container: AppDependencyContainer

    init(container: AppDependencyContainer) {
        self.container = container
    }

    var dataSet: DataSet { container.dataSet }

    func load() async {
        scenario = await container.scenarioController.currentScenario()
        holdingCount = (try? container.portfolioRepository.cachedPortfolio()?.holdings.count) ?? 0
        transactionCount = (try? container.transactionRepository.transactions().count) ?? 0
        lastRefreshDate = container.portfolioRepository.lastRefreshDate()
        totalRequests = container.requestTracker.totalRequests
    }

    /// Mock API'ye aynı anda 200 istek gönderir; sayaç tam 200 artmalıdır.
    func runStressTest() async {
        isRunningStressTest = true
        let client = MockPortfolioAPIClient(
            scenarioController: MockScenarioController(),
            delay: .milliseconds(10),
            requestTracker: container.requestTracker
        )
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<200 {
                group.addTask {
                    _ = try? await client.fetchPortfolio()
                }
            }
        }
        totalRequests = container.requestTracker.totalRequests
        isRunningStressTest = false
        AppLogger.diagnostics.notice("Stres testi bitti, toplam istek: \(self.totalRequests)")
    }

    func select(_ newScenario: MockScenario) async {
        scenario = newScenario
        await container.scenarioController.setScenario(newScenario)
        AppLogger.diagnostics.notice("Senaryo değişti: \(newScenario.rawValue, privacy: .public)")
    }

    /// Seçim sonrası sekmeler yeniden kurulur ve Dashboard açılır.
    func select(_ newDataSet: DataSet) {
        do {
            try container.switchDataSet(to: newDataSet)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
