import Testing
@testable import ProductionLab

struct PortfolioCalculatorTests {
    let gain = makeHolding(symbol: "GAIN", quantity: 10, averageCost: 100, currentPrice: 120)
    let loss = makeHolding(symbol: "LOSS", quantity: 5, averageCost: 200, currentPrice: 150)

    @Test func singleHolding() {
        #expect(PortfolioCalculator.marketValue(of: gain) == 1_200)
        #expect(PortfolioCalculator.cost(of: gain) == 1_000)
        #expect(PortfolioCalculator.profitLoss(of: gain) == 200)
        #expect(PortfolioCalculator.profitLossPercent(of: gain) == 20)
    }

    @Test func portfolioTotals() {
        let summary = PortfolioCalculator.summary(of: [gain, loss])
        #expect(summary.totalValue == 1_950)
        #expect(summary.totalCost == 2_000)
        #expect(summary.profitLoss == -50)
        #expect(summary.profitLossPercent == -2.5)
        #expect(summary.holdingCount == 2)
    }

    @Test func emptyPortfolio() {
        let summary = PortfolioCalculator.summary(of: [])
        #expect(summary.totalValue == 0)
        #expect(summary.profitLossPercent == 0)
    }

    @Test func zeroCostGivesZeroPercent() {
        let free = makeHolding(symbol: "FREE", quantity: 10, averageCost: 0, currentPrice: 50)
        #expect(PortfolioCalculator.profitLoss(of: free) == 500)
        #expect(PortfolioCalculator.profitLossPercent(of: free) == 0)
    }
}
