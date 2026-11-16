import Foundation
import Observation
import OSLog
import SwiftData

/// Uygulamadaki tüm bağımlılıkları bir kez oluşturur ve ViewModel'lere init üzerinden verir.
/// Testlerde bu sınıf yerine fake nesneler doğrudan ViewModel'e verilir.
/// `@Observable`: veri seti değişince RootView ekranları yeni repository'lerle yeniden kurar.
@MainActor
@Observable
final class AppDependencyContainer {
    let scenarioController = MockScenarioController(scenario: AppInfo.launchScenario ?? .success)
    let requestTracker = RequestTracker()
    let authService: AuthenticationService

    private(set) var dataSet: DataSet = .standard
    private(set) var portfolioRepository: PortfolioRepository
    private(set) var transactionRepository: TransactionRepository

    /// Normal veritabanı (diskte). Performans veri seti seçilse bile silinmez veya değişmez.
    private let mainModelContainer: ModelContainer
    /// Performans veri seti için bellekte ayrı veritabanı. Normal veri setine dönünce bırakılır.
    private var performanceModelContainer: ModelContainer?

    /// Token'ın nerede saklanacağı tek yerden belirlenir.
    nonisolated static func makeDefaultSecureStorage() -> SecureStorage {
        KeychainStorage()
    }

    init(inMemory: Bool = AppInfo.isRunningTests,
         secureStorage: SecureStorage = AppDependencyContainer.makeDefaultSecureStorage()) {
        do {
            mainModelContainer = try Self.makeModelContainer(inMemory: inMemory)
        } catch {
            // Veritabanı hiç açılamıyorsa uygulama çalışamaz.
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }

        let context = mainModelContainer.mainContext
        let apiClient = MockPortfolioAPIClient(scenarioController: scenarioController, requestTracker: requestTracker)
        portfolioRepository = DefaultPortfolioRepository(apiClient: apiClient, context: context)
        transactionRepository = DefaultTransactionRepository(context: context)
        authService = AuthenticationService(storage: secureStorage)

        do {
            try DataSeeder.seedIfNeeded(context: context)
        } catch {
            AppLogger.persistence.error("Seed başarısız: \(error.localizedDescription)")
        }

        // UI testleri temiz bir oturumla başlamak için "-reset-session" argümanını kullanır.
        if AppInfo.shouldResetSession {
            authService.logout()
        }
        authService.restoreSession()
    }

    static func makeModelContainer(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: PortfolioEntity.self, HoldingEntity.self, TransactionEntity.self, SyncMetadataEntity.self,
            configurations: configuration
        )
    }

    // MARK: - Veri seti değiştirme (Diagnostics)

    func switchDataSet(to newDataSet: DataSet) throws {
        guard newDataSet != dataSet else { return }

        let context: ModelContext
        var apiClient = MockPortfolioAPIClient(scenarioController: scenarioController, requestTracker: requestTracker)

        if newDataSet == .standard {
            // Normale dönüş: performans veritabanı bırakılır, ana veritabanı olduğu gibi kullanılır.
            performanceModelContainer = nil
            context = mainModelContainer.mainContext
        } else {
            // Her seçimde temiz bir bellek veritabanı oluşturulup üretilmiş veriyle doldurulur.
            let container = try Self.makeModelContainer(inMemory: true)
            try DataSeeder.seedIfNeeded(context: container.mainContext, generatedHoldingCount: newDataSet.rawValue)
            performanceModelContainer = container
            context = container.mainContext
            apiClient.generatedHoldingCount = newDataSet.rawValue
        }

        portfolioRepository = DefaultPortfolioRepository(apiClient: apiClient, context: context)
        transactionRepository = DefaultTransactionRepository(context: context)
        dataSet = newDataSet
        AppLogger.performance.notice("Veri seti değişti: \(newDataSet.rawValue) varlık")
    }

    // MARK: - ViewModel üreticileri

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: authService)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(portfolioRepository: portfolioRepository, transactionRepository: transactionRepository)
    }

    func makeHoldingsViewModel() -> HoldingsViewModel {
        HoldingsViewModel(portfolioRepository: portfolioRepository)
    }

    func makeActivityViewModel() -> ActivityViewModel {
        ActivityViewModel(transactionRepository: transactionRepository)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(authService: authService)
    }

    func makeDiagnosticsViewModel() -> DiagnosticsViewModel {
        DiagnosticsViewModel(container: self)
    }
}
