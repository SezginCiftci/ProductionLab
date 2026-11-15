import Foundation
import Observation

@MainActor
@Observable
final class HoldingDetailViewModel {
    let holding: Holding
    let currencyCode: String

    init(holding: Holding, currencyCode: String) {
        self.holding = holding
        self.currencyCode = currencyCode
    }

    var marketValue: Double { PortfolioCalculator.marketValue(of: holding) }
    var cost: Double { PortfolioCalculator.cost(of: holding) }
    var profitLoss: Double { PortfolioCalculator.profitLoss(of: holding) }
    var profitLossPercent: Double { PortfolioCalculator.profitLossPercent(of: holding) }
}
