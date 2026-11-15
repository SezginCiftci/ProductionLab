import Foundation

/// Ağ katmanı sözleşmesi. Projede yalnızca çevrimdışı mock implementasyonu var.
protocol PortfolioAPIClient: Sendable {
    func fetchPortfolio() async throws -> PortfolioDTO
    func fetchHoldings() async throws -> [HoldingDTO]
}
