import Foundation

/// Performans lab'leri için deterministik büyük veri (1.000 / 5.000 varlık).
/// Aynı `count` her zaman aynı veriyi üretir; böylece ölçümler karşılaştırılabilir.
enum PerformanceDataGenerator {
    static func holdings(count: Int, portfolioID: UUID) -> [Holding] {
        var result: [Holding] = []
        for index in 0..<count {
            // Sıra numarasından sabit bir UUID üretilir (ör. ...-000000000001).
            let idText = String(format: "33333333-3333-4333-8333-%012d", index + 1)
            guard let id = UUID(uuidString: idText) else { continue }

            let averageCost = Double(10 + (index * 37) % 490)
            let priceFactor = [1.12, 0.91, 1.05, 0.97, 1.21][index % 5]

            result.append(Holding(
                id: id,
                portfolioID: portfolioID,
                symbol: "PERF\(index + 1)",
                name: "Performance Asset \(index + 1)",
                quantity: Double(1 + (index * 13) % 200),
                averageCost: averageCost,
                currentPrice: averageCost * priceFactor,
                updatedAt: Date(timeIntervalSince1970: 1_768_471_200) // 2026-01-15
            ))
        }
        return result
    }
}
