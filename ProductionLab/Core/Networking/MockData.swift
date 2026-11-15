import Foundation

/// Bundle içindeki JSON dosyalarını (Resources/MockData) okur. İnternet kullanılmaz.
enum MockData {
    static func load(_ fileName: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw AppError.fileNotFound(fileName)
        }
        return try Data(contentsOf: url)
    }

    /// Tarihler JSON'da ISO 8601 formatında: "2026-01-15T10:00:00Z"
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
