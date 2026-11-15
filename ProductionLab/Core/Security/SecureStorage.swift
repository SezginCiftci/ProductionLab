import Foundation

/// Gizli verileri (token) saklama sözleşmesi.
/// Uygulama KeychainStorage, testler InMemorySecureStorage kullanır.
protocol SecureStorage {
    func save(_ data: Data, for key: String) throws
    func read(for key: String) throws -> Data?
    func delete(for key: String) throws
}

/// Bellekte tutan basit implementasyon (testler için). Uygulama kapanınca veri kaybolur.
final class InMemorySecureStorage: SecureStorage {
    private var values: [String: Data] = [:]

    func save(_ data: Data, for key: String) throws { values[key] = data }
    func read(for key: String) throws -> Data? { values[key] }
    func delete(for key: String) throws { values[key] = nil }
}
