import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        List {
            Section("İşlem") {
                LabeledContent("Tür", value: transaction.type == .buy ? "Buy" : "Sell")
                LabeledContent("Sembol", value: transaction.symbol)
                LabeledContent("Miktar", value: Formatting.quantity(transaction.quantity))
                LabeledContent("Fiyat", value: Formatting.currency(transaction.price, code: currencyCode))
                LabeledContent("Tutar") {
                    Text(Formatting.currency(transaction.amount, code: currencyCode))
                        .accessibilityIdentifier("transactionDetail.amount")
                }
                LabeledContent("Tarih", value: transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            Section("Varlık") {
                LabeledContent("Holding ID", value: holdingIDText)
                    .font(.footnote)
            }
        }
        .navigationTitle(transaction.symbol)
        .accessibilityIdentifier("transactionDetail.view")
    }

    /// Bağlı varlığın kimliği.
    private var holdingIDText: String {
        transaction.holdingID!.uuidString
    }
}
