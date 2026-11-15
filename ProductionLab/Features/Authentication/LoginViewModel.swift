import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var username = ""
    var password = ""
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    var canSubmit: Bool {
        !isLoading && !username.isEmpty && !password.isEmpty
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            try await authService.login(username: username, password: password)
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
