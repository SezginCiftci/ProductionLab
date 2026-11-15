import Foundation

/// Diagnostics ekranından seçilen mock API davranışı.
enum MockScenario: String, CaseIterable, Sendable {
    case success, slowResponse, serverError, emptyResponse, invalidJSON

    var title: String {
        switch self {
        case .success: return "Başarılı (500 ms)"
        case .slowResponse: return "Yavaş cevap (8 sn)"
        case .serverError: return "Sunucu hatası (HTTP 503)"
        case .emptyResponse: return "Boş holdings"
        case .invalidJSON: return "Bozuk JSON"
        }
    }
}

/// Seçili senaryoyu tutar. `actor` olduğu için farklı thread'lerden
/// aynı anda okunup yazılsa bile veri yarışı (data race) oluşmaz.
actor MockScenarioController {
    private var scenario: MockScenario

    init(scenario: MockScenario = .success) {
        self.scenario = scenario
    }

    func setScenario(_ value: MockScenario) { scenario = value }
    func currentScenario() -> MockScenario { scenario }
}
