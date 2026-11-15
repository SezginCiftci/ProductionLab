import SwiftUI

struct HoldingDetailView: View {
    let viewModel: HoldingDetailViewModel

    var body: some View {
        let holding = viewModel.holding
        let code = viewModel.currencyCode

        List {
            Section("Pozisyon") {
                LabeledContent("İsim", value: holding.name)
                LabeledContent("Miktar", value: Formatting.quantity(holding.quantity))
                LabeledContent("Ortalama maliyet", value: Formatting.currency(holding.averageCost, code: code))
                LabeledContent("Güncel fiyat", value: Formatting.currency(holding.currentPrice, code: code))
            }
            Section("Performans") {
                LabeledContent("Piyasa değeri") {
                    Text(Formatting.currency(viewModel.marketValue, code: code))
                        .accessibilityIdentifier("holdingDetail.marketValue")
                }
                LabeledContent("Maliyet", value: Formatting.currency(viewModel.cost, code: code))
                LabeledContent("Kâr / zarar") {
                    Text(Formatting.signedCurrency(viewModel.profitLoss, code: code))
                        .foregroundStyle(viewModel.profitLoss >= 0 ? .green : .red)
                }
                LabeledContent("Getiri", value: Formatting.percent(viewModel.profitLossPercent))
                LabeledContent("Güncellenme", value: holding.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle(holding.symbol)
        .accessibilityIdentifier("holdingDetail.view")
    }
}
