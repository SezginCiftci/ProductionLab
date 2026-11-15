import SwiftUI

struct HoldingsView: View {
    @Bindable var viewModel: HoldingsViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.visibleHoldings) { holding in
                        NavigationLink(value: holding) {
                            HoldingRow(holding: holding, currencyCode: viewModel.currencyCode)
                        }
                        .accessibilityIdentifier("holdings.row.\(holding.symbol)")
                    }
                } header: {
                    Text("\(viewModel.visibleHoldings.count) / \(viewModel.holdings.count) varlık")
                        .accessibilityIdentifier("holdings.count")
                }
            }
            .overlay {
                if let message = viewModel.errorMessage {
                    ContentUnavailableView("Varlıklar yüklenemedi", systemImage: "exclamationmark.triangle",
                                           description: Text(message))
                } else if viewModel.visibleHoldings.isEmpty {
                    ContentUnavailableView("Sonuç yok", systemImage: "magnifyingglass")
                        .accessibilityIdentifier("holdings.empty")
                }
            }
            .navigationTitle("Holdings")
            .searchable(text: $viewModel.searchText, prompt: "Sembol veya isim")
            .toolbar {
                Menu {
                    Picker("Sıralama", selection: $viewModel.sortOption) {
                        ForEach(HoldingSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .accessibilityIdentifier("holdings.sortPicker")
                } label: {
                    Label("Sırala", systemImage: "arrow.up.arrow.down")
                }
                .accessibilityIdentifier("holdings.sort")
            }
            .navigationDestination(for: Holding.self) { holding in
                HoldingDetailView(viewModel: HoldingDetailViewModel(holding: holding, currencyCode: viewModel.currencyCode))
            }
        }
        .onAppear { viewModel.load() }
    }
}

private struct HoldingRow: View {
    let holding: Holding
    let currencyCode: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(holding.symbol).font(.headline)
                Text(holding.name).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(Formatting.currency(PortfolioCalculator.marketValue(of: holding), code: currencyCode))
                Text(Formatting.percent(PortfolioCalculator.profitLossPercent(of: holding)))
                    .font(.caption)
                    .foregroundStyle(PortfolioCalculator.profitLoss(of: holding) >= 0 ? .green : .red)
            }
        }
    }
}
