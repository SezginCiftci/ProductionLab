import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class HoldingDetailViewModel {
    let holding: Holding
    let currencyCode: String
    /// Her saniye değişen simüle "canlı" fiyat (gerçek bir fiyat akışı yok).
    private(set) var livePrice: Double
    private var tick = 0

    init(holding: Holding, currencyCode: String) {
        self.holding = holding
        self.currencyCode = currencyCode
        self.livePrice = holding.currentPrice
    }

    deinit {
        // Memory lab'inde ekran kapandığında bu satırın loglanıp loglanmadığına bakılır.
        AppLogger.diagnostics.debug("HoldingDetailViewModel deinit")
    }

    var marketValue: Double { PortfolioCalculator.marketValue(of: holding) }
    var cost: Double { PortfolioCalculator.cost(of: holding) }
    var profitLoss: Double { PortfolioCalculator.profitLoss(of: holding) }
    var profitLossPercent: Double { PortfolioCalculator.profitLossPercent(of: holding) }

    /// Canlı fiyat simülasyonu. View'ın `.task` modifier'ından çağrılır:
    /// ekran kapanınca SwiftUI görevi iptal eder, döngü biter ve ViewModel serbest kalır.
    func runLivePriceUpdates() async {
        while true {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return // iptal edildi
            }
            tick += 1
            // Deterministik küçük dalgalanma: ±%0,5
            livePrice = holding.currentPrice * (1 + 0.005 * sin(Double(tick)))
        }
    }
}
