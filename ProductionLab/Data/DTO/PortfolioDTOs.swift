import Foundation

// DTO'lar JSON dosyalarının birebir karşılığıdır.
// Codable sayesinde JSONDecoder ile otomatik çözülürler.

struct PortfolioDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let currencyCode: String
}

struct HoldingDTO: Codable, Sendable {
    let id: UUID
    let portfolioID: UUID
    let symbol: String
    let name: String
    let quantity: Double
    let averageCost: Double
    let currentPrice: Double
    let updatedAt: Date
}

struct TransactionDTO: Codable, Sendable {
    let id: UUID
    let portfolioID: UUID
    let holdingID: UUID?
    let type: TransactionType
    let symbol: String
    let quantity: Double
    let price: Double
    let createdAt: Date
}
