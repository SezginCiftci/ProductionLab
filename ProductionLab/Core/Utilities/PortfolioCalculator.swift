import Foundation

/// Dashboard'da gösterilen toplam değerler.
struct PortfolioSummary: Equatable {
    let totalValue: Double
    let totalCost: Double
    let profitLoss: Double
    let profitLossPercent: Double
    let holdingCount: Int
}

/// Tüm portföy hesaplamaları burada yapılır.
/// Demo kolaylığı için Double kullanılıyor; gerçek finans uygulamasında Decimal tercih edilmeli.
enum PortfolioCalculator {
    /// Piyasa değeri = miktar × güncel fiyat
    static func marketValue(of holding: Holding) -> Double {
        holding.quantity * holding.currentPrice
    }

    /// Maliyet = miktar × ortalama maliyet
    static func cost(of holding: Holding) -> Double {
        holding.quantity * holding.averageCost
    }

    /// Kâr/zarar = piyasa değeri − maliyet
    static func profitLoss(of holding: Holding) -> Double {
        marketValue(of: holding) - cost(of: holding)
    }

    static func profitLossPercent(of holding: Holding) -> Double {
        percent(profitLoss: profitLoss(of: holding), cost: cost(of: holding))
    }

    /// Maliyet sıfırdan büyükse (kâr/zarar ÷ maliyet) × 100, değilse 0.
    static func percent(profitLoss: Double, cost: Double) -> Double {
        if cost > 0 {
            return profitLoss / cost * 100
        }
        return 0
    }

    static func summary(of holdings: [Holding]) -> PortfolioSummary {
        var totalValue = 0.0
        var totalCost = 0.0
        for holding in holdings {
            totalValue += marketValue(of: holding)
            totalCost += cost(of: holding)
        }
        let profitLoss = totalValue - totalCost
        return PortfolioSummary(
            totalValue: totalValue,
            totalCost: totalCost,
            profitLoss: profitLoss,
            profitLossPercent: percent(profitLoss: profitLoss, cost: totalCost),
            holdingCount: holdings.count
        )
    }
}
