import Foundation
import Testing
@testable import ProductionLab

/// Gerçek KeychainStorage'ı simülatörün Keychain'inde dener.
/// Uygulamanın kendi kayıtlarına dokunmamak için ayrı bir servis adı ve her testte yeni anahtar kullanılır.
struct KeychainStorageTests {
    let storage = KeychainStorage(service: "com.productionlab.ios.tests")
    let key = "test-\(UUID().uuidString)"

    @Test func saveReadUpdateDelete() throws {
        try storage.save(Data("ilk".utf8), for: key)
        #expect(try storage.read(for: key) == Data("ilk".utf8))

        // Aynı anahtara tekrar kaydetmek değeri günceller (errSecDuplicateItem → SecItemUpdate).
        try storage.save(Data("ikinci".utf8), for: key)
        #expect(try storage.read(for: key) == Data("ikinci".utf8))

        try storage.delete(for: key)
        #expect(try storage.read(for: key) == nil)
    }

    @Test func readingMissingKeyReturnsNil() throws {
        #expect(try storage.read(for: key) == nil)
    }

    @Test func deletingMissingKeyDoesNotThrow() throws {
        try storage.delete(for: key)
    }

    @Test func errorMessageContainsStatusCode() {
        let error = KeychainError(status: errSecItemNotFound)
        #expect(error.localizedDescription.contains("-25300"))
    }
}
