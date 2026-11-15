import Foundation
import SwiftData

// SwiftData'da saklanan tablolar. İlişkiler UUID alanlarıyla tutulur (portfolioID, holdingID);
// böylece şema basit kalır ve tüm workshop branch'lerinde aynı olur.

@Model
final class PortfolioEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var currencyCode: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID, name: String, currencyCode: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.currencyCode = currencyCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class HoldingEntity {
    @Attribute(.unique) var id: UUID
    var portfolioID: UUID
    var symbol: String
    var name: String
    var quantity: Double
    var averageCost: Double
    var currentPrice: Double
    var updatedAt: Date

    init(id: UUID, portfolioID: UUID, symbol: String, name: String,
         quantity: Double, averageCost: Double, currentPrice: Double, updatedAt: Date) {
        self.id = id
        self.portfolioID = portfolioID
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.averageCost = averageCost
        self.currentPrice = currentPrice
        self.updatedAt = updatedAt
    }
}

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: UUID
    var portfolioID: UUID
    var holdingID: UUID?
    /// "buy" veya "sell" (TransactionType.rawValue)
    var type: String
    var symbol: String
    var quantity: Double
    var price: Double
    var createdAt: Date

    init(id: UUID, portfolioID: UUID, holdingID: UUID?, type: String,
         symbol: String, quantity: Double, price: Double, createdAt: Date) {
        self.id = id
        self.portfolioID = portfolioID
        self.holdingID = holdingID
        self.type = type
        self.symbol = symbol
        self.quantity = quantity
        self.price = price
        self.createdAt = createdAt
    }
}

/// Son başarılı yenilemenin ne zaman yapıldığını saklar.
@Model
final class SyncMetadataEntity {
    @Attribute(.unique) var id: UUID
    var resourceType: String
    var syncStatus: String
    var lastSyncedAt: Date?

    init(resourceType: String, syncStatus: String, lastSyncedAt: Date?) {
        self.id = UUID()
        self.resourceType = resourceType
        self.syncStatus = syncStatus
        self.lastSyncedAt = lastSyncedAt
    }
}
