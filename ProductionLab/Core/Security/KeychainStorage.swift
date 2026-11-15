import Foundation
import Security

/// Keychain işlemleri başarısız olduğunda fırlatılan hata.
/// OSStatus, Security framework'ün döndürdüğü sayısal hata kodudur (ör. -25300).
struct KeychainError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "Bilinmeyen hata"
        return "Keychain hatası (\(status)): \(message)"
    }
}

/// Token'ı iOS Keychain'de saklar.
/// - Yalnızca cihaz kilidi açıkken okunabilir.
/// - iCloud'a veya başka cihaza aktarılmaz ("ThisDeviceOnly").
final class KeychainStorage: SecureStorage {
    private let service: String

    init(service: String = "com.productionlab.ios") {
        self.service = service
    }

    func save(_ data: Data, for key: String) throws {
        // Önce eklemeyi dene; aynı anahtar zaten varsa güncelle.
        var addQuery = baseQuery(for: key)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }

        if addStatus == errSecDuplicateItem {
            let attributes = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(baseQuery(for: key) as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError(status: updateStatus)
            }
            return
        }

        throw KeychainError(status: addStatus)
    }

    func read(for key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil // kayıt yok: hata değil
        }
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
        return result as? Data
    }

    func delete(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        // Silinecek kayıt zaten yoksa sorun değil.
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    /// Tüm işlemlerde ortak olan alanlar: kayıt türü, servis adı ve anahtar.
    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
