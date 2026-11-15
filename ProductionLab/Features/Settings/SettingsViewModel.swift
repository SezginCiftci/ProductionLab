import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    let version = AppInfo.version
    let build = AppInfo.build
    let configuration = AppInfo.configuration
    let environment = AppInfo.environment

    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    func logout() {
        authService.logout()
    }
}
