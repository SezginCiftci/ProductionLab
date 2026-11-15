import Foundation

/// Bir ekranın veri yükleme durumu.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}
