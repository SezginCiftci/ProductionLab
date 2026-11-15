import Foundation

/// Ekranlarda ortak kullanılan sayı/para biçimlendirmeleri.
enum Formatting {
    static func currency(_ value: Double, code: String) -> String {
        value.formatted(.currency(code: code))
    }

    static func signedCurrency(_ value: Double, code: String) -> String {
        value.formatted(.currency(code: code).sign(strategy: .always()))
    }

    static func percent(_ value: Double) -> String {
        (value / 100).formatted(.percent.precision(.fractionLength(2)).sign(strategy: .always()))
    }

    static func quantity(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...4)))
    }
}
