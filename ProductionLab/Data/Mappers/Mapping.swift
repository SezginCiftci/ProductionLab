import Foundation

// Tipler arası dönüşümler tek yerde:
// DTO → Domain (API cevabı için) ve Domain ↔ Entity (SwiftData için).

// MARK: - DTO → Domain

extension PortfolioDTO {
    func toDomain(holdings: [Holding]) -> Portfolio {
        Portfolio(id: id, name: name, currencyCode: currencyCode, holdings: holdings)
    }
}

extension HoldingDTO {
    func toDomain() -> Holding {
        Holding(id: id, portfolioID: portfolioID, symbol: symbol, name: name,
                quantity: quantity, averageCost: averageCost,
                currentPrice: currentPrice, updatedAt: updatedAt)
    }
}

extension TransactionDTO {
    func toDomain() -> Transaction {
        Transaction(id: id, portfolioID: portfolioID, holdingID: holdingID, type: type,
                    symbol: symbol, quantity: quantity, price: price, createdAt: createdAt)
    }
}

// MARK: - Domain → DTO (performans verisini mock API cevabı gibi döndürmek için)

extension HoldingDTO {
    init(holding: Holding) {
        self.init(id: holding.id, portfolioID: holding.portfolioID, symbol: holding.symbol,
                  name: holding.name, quantity: holding.quantity, averageCost: holding.averageCost,
                  currentPrice: holding.currentPrice, updatedAt: holding.updatedAt)
    }
}

// MARK: - Domain ↔ Entity

extension PortfolioEntity {
    convenience init(portfolio: Portfolio, date: Date) {
        self.init(id: portfolio.id, name: portfolio.name, currencyCode: portfolio.currencyCode,
                  createdAt: date, updatedAt: date)
    }

    func toDomain(holdings: [Holding]) -> Portfolio {
        Portfolio(id: id, name: name, currencyCode: currencyCode, holdings: holdings)
    }
}

extension HoldingEntity {
    convenience init(holding: Holding) {
        self.init(id: holding.id, portfolioID: holding.portfolioID, symbol: holding.symbol,
                  name: holding.name, quantity: holding.quantity, averageCost: holding.averageCost,
                  currentPrice: holding.currentPrice, updatedAt: holding.updatedAt)
    }

    /// Var olan kaydı yeni değerlerle günceller (id değişmez).
    func update(from holding: Holding) {
        symbol = holding.symbol
        name = holding.name
        quantity = holding.quantity
        averageCost = holding.averageCost
        currentPrice = holding.currentPrice
        updatedAt = holding.updatedAt
    }

    func toDomain() -> Holding {
        Holding(id: id, portfolioID: portfolioID, symbol: symbol, name: name,
                quantity: quantity, averageCost: averageCost,
                currentPrice: currentPrice, updatedAt: updatedAt)
    }
}

extension TransactionEntity {
    convenience init(transaction: Transaction) {
        self.init(id: transaction.id, portfolioID: transaction.portfolioID,
                  holdingID: transaction.holdingID, type: transaction.type.rawValue,
                  symbol: transaction.symbol, quantity: transaction.quantity,
                  price: transaction.price, createdAt: transaction.createdAt)
    }

    func toDomain() -> Transaction {
        Transaction(id: id, portfolioID: portfolioID, holdingID: holdingID,
                    type: TransactionType(rawValue: type) ?? .buy,
                    symbol: symbol, quantity: quantity, price: price, createdAt: createdAt)
    }
}
