import Foundation
import Observation

/// Dashboard'da gösterilen veri.
struct DashboardContent {
    let portfolioName: String
    let currencyCode: String
    let summary: PortfolioSummary
    let recentTransactions: [Transaction]
}

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var state: LoadState<DashboardContent> = .idle
    private(set) var isRefreshing = false
    /// Önbellek varken refresh başarısız olursa gösterilen, ekranı kapatmayan hata mesajı.
    private(set) var errorMessage: String?
    private(set) var lastRefreshDate: Date?
    /// Devam eden yenileme. Testler `await viewModel.refreshTask?.value` ile bitmesini bekler.
    private(set) var refreshTask: Task<Void, Never>?

    private let portfolioRepository: PortfolioRepository
    private let transactionRepository: TransactionRepository

    init(portfolioRepository: PortfolioRepository, transactionRepository: TransactionRepository) {
        self.portfolioRepository = portfolioRepository
        self.transactionRepository = transactionRepository
    }

    /// Yüklü veri varsa döndürür (yoksa nil).
    var content: DashboardContent? {
        if case .loaded(let content) = state {
            return content
        }
        return nil
    }

    /// Ekran ilk açıldığında: önce önbelleği hemen göster, sonra yenilemeyi başlat.
    func onAppear() {
        guard case .idle = state else { return } // sekme değişiminde tekrar çalışmasın
        loadCache()
        refresh()
    }

    func loadCache() {
        do {
            if let portfolio = try portfolioRepository.cachedPortfolio() {
                state = .loaded(try makeContent(from: portfolio))
            } else {
                state = .loading
            }
            lastRefreshDate = portfolioRepository.lastRefreshDate()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Yeni bir yenileme başlatır.
    func refresh() {
        isRefreshing = true
        refreshTask = Task {
            await performRefresh()
        }
    }

    /// Ekran artık yenilemeye ihtiyaç duymuyorsa çağrılır. Önbellek korunur.
    func cancelRefresh() {
        refreshTask?.cancel()
        isRefreshing = false
    }

    private func performRefresh() async {
        errorMessage = nil

        do {
            let portfolio = try await portfolioRepository.refreshPortfolio()
            state = .loaded(try makeContent(from: portfolio))
            lastRefreshDate = portfolioRepository.lastRefreshDate()
        } catch is CancellationError {
            // İptal bir hata değildir: mesaj gösterme, önbelleği koru.
            return
        } catch {
            if Task.isCancelled { return }

            if content != nil {
                errorMessage = error.localizedDescription // önbellek ekranda kalır
            } else {
                state = .failed(error.localizedDescription)
            }
        }
        isRefreshing = false
    }

    private func makeContent(from portfolio: Portfolio) throws -> DashboardContent {
        DashboardContent(
            portfolioName: portfolio.name,
            currencyCode: portfolio.currencyCode,
            summary: PortfolioCalculator.summary(of: portfolio.holdings),
            recentTransactions: try transactionRepository.recentTransactions(limit: 5)
        )
    }
}
