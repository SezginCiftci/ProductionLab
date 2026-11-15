import Foundation
import Testing
@testable import ProductionLab

/// Gerçek Keychain yerine InMemorySecureStorage kullanır.
@MainActor
struct AuthenticationTests {
    let storage = InMemorySecureStorage()
    var service: AuthenticationService {
        AuthenticationService(storage: storage, loginDelay: .zero)
    }

    @Test func validLoginSavesToken() async throws {
        let service = service
        try await service.login(username: "demo", password: "demo123")

        #expect(service.isLoggedIn)
        let data = try #require(try storage.read(for: AuthenticationService.tokenKey))
        let token = String(decoding: data, as: UTF8.self)
        #expect(AuthenticationService.isValidToken(token))
        #expect(!token.contains("demo123")) // şifre saklanmaz
    }

    @Test func invalidLoginFails() async throws {
        let service = service
        await #expect(throws: AppError.invalidCredentials) {
            try await service.login(username: "demo", password: "wrong")
        }
        #expect(!service.isLoggedIn)
        #expect(try storage.read(for: AuthenticationService.tokenKey) == nil)
    }

    @Test func restoreAfterRelaunchAndLogout() async throws {
        try await service.login(username: "demo", password: "demo123")

        let reopened = service // uygulamanın yeniden açılması gibi: yeni servis, aynı storage
        reopened.restoreSession()
        #expect(reopened.isLoggedIn)

        reopened.logout()
        #expect(!reopened.isLoggedIn)
        #expect(try storage.read(for: AuthenticationService.tokenKey) == nil)

        let reopenedAgain = service
        reopenedAgain.restoreSession()
        #expect(!reopenedAgain.isLoggedIn)
    }

    @Test func invalidTokenIsNotRestored() throws {
        try storage.save(Data("bozuk-token".utf8), for: AuthenticationService.tokenKey)
        let service = service
        service.restoreSession()
        #expect(!service.isLoggedIn)
    }

    @Test func tokenFormat() {
        #expect(AuthenticationService.isValidToken("demo-token-\(UUID().uuidString)"))
        #expect(!AuthenticationService.isValidToken("demo-token-123"))
        #expect(!AuthenticationService.isValidToken("baska-\(UUID().uuidString)"))
    }

    // MARK: Storage hataları

    @Test func saveFailureMeansNotLoggedIn() async {
        let service = AuthenticationService(storage: FailingSecureStorage(), loginDelay: .zero)
        await #expect(throws: FailingSecureStorage.Failure.self) {
            try await service.login(username: "demo", password: "demo123")
        }
        #expect(!service.isLoggedIn)
    }

    @Test func readFailureMeansNoSession() {
        let service = AuthenticationService(storage: FailingSecureStorage(), loginDelay: .zero)
        service.restoreSession()
        #expect(!service.isLoggedIn)
    }

    @Test func logoutClearsSessionEvenIfDeleteFails() {
        let service = AuthenticationService(storage: FailingSecureStorage(), loginDelay: .zero)
        service.logout()
        #expect(!service.isLoggedIn)
    }
}

@MainActor
struct LoginViewModelTests {
    let authService = AuthenticationService(storage: InMemorySecureStorage(), loginDelay: .zero)

    @Test func submitIsDisabledUntilBothFieldsAreFilled() {
        let viewModel = LoginViewModel(authService: authService)
        #expect(!viewModel.canSubmit)
        viewModel.username = "demo"
        #expect(!viewModel.canSubmit)
        viewModel.password = "x"
        #expect(viewModel.canSubmit)
    }

    @Test func wrongPasswordShowsError() async {
        let viewModel = LoginViewModel(authService: authService)
        viewModel.username = "demo"
        viewModel.password = "wrong"

        await viewModel.login()

        #expect(viewModel.errorMessage == AppError.invalidCredentials.errorDescription)
        #expect(!viewModel.isLoading)
        #expect(!authService.isLoggedIn)
    }

    @Test func successfulLoginClearsPassword() async {
        let viewModel = LoginViewModel(authService: authService)
        viewModel.username = "demo"
        viewModel.password = "demo123"

        await viewModel.login()

        #expect(authService.isLoggedIn)
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }
}
