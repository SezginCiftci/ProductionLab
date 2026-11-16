import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Dashboard")
                .toolbar {
                    if viewModel.isRefreshing {
                        ToolbarItem(placement: .topBarLeading) {
                            // Kullanıcı artık beklemek istemiyorsa isteği iptal eder; önbellek korunur.
                            Button("Vazgeç") { viewModel.cancelRefresh() }
                                .accessibilityIdentifier("dashboard.cancelRefresh")
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            ProgressView()
                                .accessibilityIdentifier("dashboard.refreshing")
                        }
                    }
                    // Yenileme sürerken de basılabilir: yeni istek eskisini iptal eder.
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            viewModel.refresh()
                        }
                        .accessibilityIdentifier("dashboard.refresh")
                    }
                }
        }
        .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Portföy yükleniyor…")
                .accessibilityIdentifier("dashboard.loading")
        case .failed(let message):
            ContentUnavailableView {
                Label("Portföy yüklenemedi", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Tekrar dene") { viewModel.refresh() }
                    .accessibilityIdentifier("dashboard.retry")
            }
            .accessibilityIdentifier("dashboard.error")
        case .loaded(let content):
            loadedList(content)
        }
    }

    private func loadedList(_ content: DashboardContent) -> some View {
        List {
            if let message = viewModel.errorMessage {
                Section {
                    Label(message, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                        .accessibilityElement(children: .combine) // ikon + metin tek öğe
                        .accessibilityIdentifier("dashboard.refreshError")
                }
            }

            Section(content.portfolioName) {
                LabeledContent("Toplam değer") {
                    Text(Formatting.currency(content.summary.totalValue, code: content.currencyCode))
                        .accessibilityIdentifier("dashboard.totalValue")
                }
                LabeledContent("Kâr / zarar") {
                    Text(Formatting.signedCurrency(content.summary.profitLoss, code: content.currencyCode))
                        .foregroundStyle(content.summary.profitLoss >= 0 ? .green : .red)
                        .accessibilityIdentifier("dashboard.profitLoss")
                }
                LabeledContent("Getiri") {
                    Text(Formatting.percent(content.summary.profitLossPercent))
                        .accessibilityIdentifier("dashboard.profitLossPercent")
                }
                LabeledContent("Varlık sayısı") {
                    Text("\(content.summary.holdingCount)")
                        .accessibilityIdentifier("dashboard.holdingCount")
                }
                LabeledContent("Son yenileme") {
                    Text(lastRefreshText)
                        .accessibilityIdentifier("dashboard.lastRefresh")
                }
            }

            Section("Son işlemler") {
                ForEach(content.recentTransactions) { transaction in
                    TransactionRow(transaction: transaction, currencyCode: content.currencyCode)
                }
            }
        }
        .refreshable {
            viewModel.refresh()
            await viewModel.refreshTask?.value
        }
    }

    private var lastRefreshText: String {
        guard let date = viewModel.lastRefreshDate else { return "Hiç" }
        return date.formatted(date: .abbreviated, time: .standard)
    }
}
