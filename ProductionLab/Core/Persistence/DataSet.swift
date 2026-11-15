import Foundation

/// Diagnostics'ten seçilen veri seti.
/// - standard: normal veritabanı (diskte, 20 varlık)
/// - large / huge: performans lab'leri için bellekte ayrı bir veritabanı.
///   Normal veriye hiç dokunulmaz; "standard"a dönünce her şey eskisi gibidir.
enum DataSet: Int, CaseIterable, Identifiable {
    case standard = 20
    case large = 1_000
    case huge = 5_000

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .standard: return "Normal (20 varlık)"
        case .large: return "Performans (1.000 varlık)"
        case .huge: return "Performans (5.000 varlık)"
        }
    }
}
