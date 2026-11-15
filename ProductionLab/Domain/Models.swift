import Foundation

// Domain modelleri: uygulamanın geri kalanı yalnızca bu tiplerle çalışır.
// DTO (JSON) ve SwiftData entity tipleri ayrıdır; dönüşüm Data/Mappers içinde yapılır.

struct Portfolio: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let currencyCode: String
    let holdings: [Holding]
}

struct Holding: Identifiable, Sendable, Hashable {
    let id: UUID
    let portfolioID: UUID
    let symbol: String
    let name: String
    let quantity: Double
    let averageCost: Double
    let currentPrice: Double
    let updatedAt: Date
}

enum TransactionType: String, Codable, Sendable, CaseIterable {
    case buy, sell
}

struct Transaction: Identifiable, Sendable, Hashable {
    let id: UUID
    let portfolioID: UUID
    let holdingID: UUID?
    let type: TransactionType
    let symbol: String
    let quantity: Double
    let price: Double
    let createdAt: Date

    /// İşlem tutarı = miktar × fiyat
    var amount: Double { quantity * price }
}
