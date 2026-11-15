import Foundation
import SwiftData

/// İşlem geçmişini SwiftData'dan okur.
@MainActor
final class DefaultTransactionRepository: TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func transactions() throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func recentTransactions(limit: Int) throws -> [Transaction] {
        var descriptor = FetchDescriptor<TransactionEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { $0.toDomain() }
    }
}
