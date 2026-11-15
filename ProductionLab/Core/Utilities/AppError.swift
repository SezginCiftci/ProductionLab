import Foundation

/// Uygulamaya özel hatalar. JSON decode hataları (DecodingError) olduğu gibi kullanılır.
/// Not: CancellationError bir hata gibi gösterilmez, ViewModel'de ayrıca yakalanır.
enum AppError: LocalizedError, Equatable {
    case server(statusCode: Int)
    case fileNotFound(String)
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .server(let statusCode):
            return "Sunucuya ulaşılamadı (HTTP \(statusCode))."
        case .fileNotFound(let name):
            return "Mock veri dosyası bulunamadı: \(name).json"
        case .invalidCredentials:
            return "Kullanıcı adı veya şifre hatalı."
        }
    }
}
