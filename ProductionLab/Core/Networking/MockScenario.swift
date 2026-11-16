import Foundation

/// Diagnostics ekranından seçilen mock API davranışı.
enum MockScenario: String, CaseIterable, Sendable {
    case success, slowResponse, serverError, emptyResponse, invalidJSON
    /// Stale response lab'i: istekler sırayla A (8 sn, eski fiyat) ve B (500 ms, yeni fiyat) döner.
    case staleResponse

    var title: String {
        switch self {
        case .success: return "Başarılı (500 ms)"
        case .slowResponse: return "Yavaş cevap (8 sn)"
        case .serverError: return "Sunucu hatası (HTTP 503)"
        case .emptyResponse: return "Boş holdings"
        case .invalidJSON: return "Bozuk JSON"
        case .staleResponse: return "Stale response demo (A: 8 sn, B: 500 ms)"
        }
    }
}

/// Seçili senaryoyu tutar. `actor` olduğu için farklı thread'lerden
/// aynı anda okunup yazılsa bile veri yarışı (data race) oluşmaz.
actor MockScenarioController {
    private var scenario: MockScenario
    /// staleResponse senaryosunda sıradaki holdings isteğinin A mı (yavaş) olacağı.
    private var nextStaleRequestIsA = true

    init(scenario: MockScenario = .success) {
        self.scenario = scenario
    }

    func setScenario(_ value: MockScenario) {
        scenario = value
        nextStaleRequestIsA = true // her seçimde A'dan başla
    }

    func currentScenario() -> MockScenario { scenario }

    /// staleResponse için: önce A, sonra B, sonra tekrar A...
    func takeNextStaleRequestIsA() -> Bool {
        let isA = nextStaleRequestIsA
        nextStaleRequestIsA.toggle()
        return isA
    }
}
