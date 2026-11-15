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
