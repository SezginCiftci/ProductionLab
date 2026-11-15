import Foundation

/// Settings ekranında gösterilen sürüm ve derleme bilgileri.
/// Değerler Configuration/Debug.xcconfig ve Release.xcconfig dosyalarından gelir.
enum AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }

    /// xcconfig'teki APP_ENVIRONMENT değeri (Info.plist'teki "AppEnvironment" anahtarı üzerinden).
    static var environment: String {
        Bundle.main.infoDictionary?["AppEnvironment"] as? String ?? "-"
    }

    static var configuration: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    /// Unit test veya UI test (-ui-testing argümanı) sırasında true.
    /// Bu durumda veriler diske değil belleğe yazılır.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    /// UI testleri "-mock-scenario serverError" gibi bir argümanla açılış senaryosunu seçer.
    static var launchScenario: MockScenario? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-mock-scenario"), index + 1 < arguments.count else {
            return nil
        }
        return MockScenario(rawValue: arguments[index + 1])
    }

    /// UI testleri "-reset-session" ile açılışta kayıtlı oturumu siler.
    static var shouldResetSession: Bool {
        ProcessInfo.processInfo.arguments.contains("-reset-session")
    }
}
