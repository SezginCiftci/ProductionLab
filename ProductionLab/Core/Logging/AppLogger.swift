import OSLog

/// Uygulamanın log kategorileri. Console.app'te subsystem'e göre filtrelenebilir.
/// Kural: loglara token, şifre veya kişisel veri yazılmaz.
enum AppLogger {
    private static let subsystem = "com.productionlab.ios"

    static let networking = Logger(subsystem: subsystem, category: "Networking")
    static let authentication = Logger(subsystem: subsystem, category: "Authentication")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let performance = Logger(subsystem: subsystem, category: "Performance")
    static let appLifecycle = Logger(subsystem: subsystem, category: "AppLifecycle")
    static let diagnostics = Logger(subsystem: subsystem, category: "Diagnostics")
}
