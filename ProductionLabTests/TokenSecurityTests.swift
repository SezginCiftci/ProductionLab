import Foundation
import Testing
@testable import ProductionLab

/// Keychain lab regresyonu: uygulamanın varsayılan kurulumu token'ı UserDefaults'a yazmamalı.
/// AppDependencyContainer'ın gerçek (varsayılan) SecureStorage'ını kullanır.
@MainActor
struct TokenSecurityTests {
    @Test func defaultSetupDoesNotWriteTokenToUserDefaults() async throws {
        let container = AppDependencyContainer(inMemory: true)
        defer { container.authService.logout() } // simülatörde kayıt bırakma

        try await container.authService.login(username: "demo", password: "demo123")

        #expect(container.authService.isLoggedIn)
        #expect(UserDefaults.standard.object(forKey: AuthenticationService.tokenKey) == nil)
    }

    @Test func defaultStorageIsKeychain() {
        #expect(AppDependencyContainer.makeDefaultSecureStorage() is KeychainStorage)
    }
}
