import Foundation
import Observation

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case buy = "Buy"
    case sell = "Sell"

    var id: String { rawValue }
}

@MainActor
@Observable
final class ActivityViewModel {
    var filter: TransactionFilter = .all
    private(set) var transactions: [Transaction] = []
    private(set) var errorMessage: String?

    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    var visibleTransactions: [Transaction] {
        switch filter {
        case .all: return transactions
        case .buy: return transactions.filter { $0.type == .buy }
        case .sell: return transactions.filter { $0.type == .sell }
        }
    }

    func load() {
        do {
            transactions = try transactionRepository.transactions()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
