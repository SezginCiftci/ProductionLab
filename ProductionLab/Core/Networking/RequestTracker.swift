import Foundation

/// Mock API'ye yapılan toplam istek sayısını tutar (Diagnostics'te gösterilir).
/// Not: Derleyici "Sendable değil" hatası verdiği için @unchecked Sendable eklendi.
final class RequestTracker: @unchecked Sendable {
    private(set) var totalRequests = 0

    func record() {
        totalRequests += 1
    }
}
