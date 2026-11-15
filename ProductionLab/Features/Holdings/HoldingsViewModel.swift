import Foundation
import Observation

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
    var searchText = ""
    var sortOption: HoldingSortOption = .symbolAscending
    private(set) var holdings: [Holding] = []
    private(set) var currencyCode = "USD"
    private(set) var errorMessage: String?

    private let portfolioRepository: PortfolioRepository

    init(portfolioRepository: PortfolioRepository) {
        self.portfolioRepository = portfolioRepository
    }

    /// Arama ve sıralama uygulanmış liste.
    var visibleHoldings: [Holding] {
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
        return result
    }

    /// SwiftData'daki kayıtlı veriyi okur. Her açılışta çağrılabilir.
    func load() {
        do {
            let portfolio = try portfolioRepository.cachedPortfolio()
            holdings = portfolio?.holdings ?? []
            currencyCode = portfolio?.currencyCode ?? "USD"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
