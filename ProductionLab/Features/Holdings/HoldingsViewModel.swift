import Foundation
import Observation
import OSLog

enum HoldingSortOption: String, CaseIterable, Identifiable {
    case symbolAscending = "Sembol A–Z"
    case symbolDescending = "Sembol Z–A"
    case marketValue = "Piyasa değeri"
    case profitLossPercent = "Kâr/zarar %"

    var id: String { rawValue }
}

@MainActor
@Observable
final class HoldingsViewModel {
    // Arama veya sıralama değişince liste bir kez yeniden hesaplanır.
    var searchText = "" {
        didSet { updateVisibleHoldings() }
    }
    var sortOption: HoldingSortOption = .symbolAscending {
        didSet { updateVisibleHoldings() }
    }

    private(set) var holdings: [Holding] = []
    /// Arama ve sıralama uygulanmış liste. View her çizimde hesaplamaz, hazır diziyi okur.
    private(set) var visibleHoldings: [Holding] = []
    /// Portföyün toplam piyasa değeri (ağırlık hesabı için, load sırasında bir kez hesaplanır).
    private(set) var totalValue = 0.0
    private(set) var currencyCode = "USD"
    private(set) var errorMessage: String?

    /// id → portföy ağırlığı (%). Satırlar her çizimde bölme yapmasın diye load() sırasında bir kez hesaplanır.
    @ObservationIgnored private var weightCache: [UUID: Double]!

    private let portfolioRepository: PortfolioRepository

    init(portfolioRepository: PortfolioRepository) {
        self.portfolioRepository = portfolioRepository
    }

    /// Varlığın portföy içindeki ağırlığı (%).
    func weight(of holding: Holding) -> Double {
        weightCache[holding.id] ?? 0
    }

    /// SwiftData'daki kayıtlı veriyi okur. Her açılışta çağrılabilir.
    func load() {
        do {
            let portfolio = try portfolioRepository.cachedPortfolio()
            holdings = portfolio?.holdings ?? []
            currencyCode = portfolio?.currencyCode ?? "USD"
            totalValue = PortfolioCalculator.summary(of: holdings).totalValue
            errorMessage = nil

            #if DEBUG
            // Önbellek süresini yalnızca geliştirme sırasında ölç.
            let elapsed = ContinuousClock().measure {
                weightCache = makeWeightCache()
            }
            AppLogger.performance.debug("Ağırlık önbelleği: \(self.holdings.count) varlık, \(elapsed)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
        }
        updateVisibleHoldings()
    }

    private func makeWeightCache() -> [UUID: Double] {
        guard totalValue > 0 else { return [:] }
        var cache: [UUID: Double] = [:]
        for holding in holdings {
            cache[holding.id] = PortfolioCalculator.marketValue(of: holding) / totalValue * 100
        }
        return cache
    }

    private func updateVisibleHoldings() {
        var result = holdings

        // Arama: büyük/küçük harf duyarsız, sembol ve isimde.
        if !searchText.isEmpty {
            result = result.filter { holding in
                holding.symbol.localizedCaseInsensitiveContains(searchText)
                    || holding.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .symbolAscending:
            result.sort { $0.symbol.localizedStandardCompare($1.symbol) == .orderedAscending }
        case .symbolDescending:
            result.sort { $0.symbol.localizedStandardCompare($1.symbol) == .orderedDescending }
        case .marketValue:
            result.sort { PortfolioCalculator.marketValue(of: $0) > PortfolioCalculator.marketValue(of: $1) }
        case .profitLossPercent:
            result.sort { PortfolioCalculator.profitLossPercent(of: $0) > PortfolioCalculator.profitLossPercent(of: $1) }
        }
        visibleHoldings = result
    }
}
