import Foundation
import Observation
import OSLog

/// Demo giriş servisi (hesap: demo / demo123). Şifre hiçbir yerde saklanmaz;
/// başarılı girişte sahte bir token üretilip SecureStorage'a yazılır.
/// `@Observable` olduğu için `isLoggedIn` değişince RootView kendini günceller.
@MainActor
@Observable
final class AuthenticationService {
    static let tokenKey = "auth.token"
    static let tokenPrefix = "demo-token-"

    private(set) var isLoggedIn = false

    private let storage: SecureStorage
    private let loginDelay: Duration

    init(storage: SecureStorage, loginDelay: Duration = .milliseconds(300)) {
        self.storage = storage
        self.loginDelay = loginDelay
    }

    func login(username: String, password: String) async throws {
        try await Task.sleep(for: loginDelay) // ağ isteği hissi için kısa bekleme

        guard username == "demo", password == "demo123" else {
            AppLogger.authentication.notice("Giriş reddedildi")
            throw AppError.invalidCredentials
        }

        let token = Self.tokenPrefix + UUID().uuidString
        try storage.save(Data(token.utf8), for: Self.tokenKey)
        isLoggedIn = true
        AppLogger.authentication.info("Giriş başarılı") // token loglanmaz
    }

    /// Uygulama açılışında çağrılır: Keychain'de geçerli formatta token varsa oturumu geri yükler.
    func restoreSession() {
        do {
            guard let data = try storage.read(for: Self.tokenKey),
                  let token = String(data: data, encoding: .utf8) else {
                AppLogger.authentication.info("Kayıtlı oturum yok")
                isLoggedIn = false
                return
            }
            isLoggedIn = Self.isValidToken(token)
            AppLogger.authentication.info("Oturum geri yükleme: \(self.isLoggedIn ? "başarılı" : "geçersiz token")")
        } catch {
            AppLogger.authentication.error("Token okunamadı: \(error.localizedDescription)")
            isLoggedIn = false
        }
    }

    /// Token'ı siler ve bellekteki oturumu kapatır.
    func logout() {
        do {
            try storage.delete(for: Self.tokenKey)
        } catch {
            AppLogger.authentication.error("Token silinemedi: \(error.localizedDescription)")
        }
        isLoggedIn = false // silme başarısız olsa bile kullanıcı çıkış yapmış sayılır
        AppLogger.authentication.info("Çıkış yapıldı")
    }

    /// Demo token formatı: "demo-token-" + UUID
    static func isValidToken(_ token: String) -> Bool {
        guard token.hasPrefix(tokenPrefix) else { return false }
        return UUID(uuidString: String(token.dropFirst(tokenPrefix.count))) != nil
    }
}
