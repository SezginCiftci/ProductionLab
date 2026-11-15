import SwiftUI

struct ActivityView: View {
    @Bindable var viewModel: ActivityViewModel
    /// Demo portföyün para birimi.
    private let currencyCode = "USD"

    var body: some View {
        NavigationStack {
            List {
                Picker("Filtre", selection: $viewModel.filter) {
                    ForEach(TransactionFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("activity.filter")

                ForEach(viewModel.visibleTransactions) { transaction in
                    NavigationLink(value: transaction) {
                        TransactionRow(transaction: transaction, currencyCode: currencyCode)
                    }
                    .accessibilityIdentifier("activity.row.\(transaction.symbol)")
                }
            }
            .overlay {
                if let message = viewModel.errorMessage {
                    ContentUnavailableView("İşlemler yüklenemedi", systemImage: "exclamationmark.triangle",
                                           description: Text(message))
                }
            }
            .navigationTitle("Activity")
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionDetailView(transaction: transaction, currencyCode: currencyCode)
            }
        }
        .onAppear { viewModel.load() }
    }
}

/// Dashboard ve Activity ekranlarında kullanılan tek satır.
struct TransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        HStack {
            Image(systemName: transaction.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(transaction.type == .buy ? .green : .orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text("\(transaction.type == .buy ? "Buy" : "Sell") \(transaction.symbol)")
                    .font(.headline)
                Text(transaction.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Formatting.currency(transaction.amount, code: currencyCode))
        }
    }
}
