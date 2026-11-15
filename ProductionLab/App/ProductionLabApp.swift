import SwiftUI

@main
struct ProductionLabApp: App {
    @State private var container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
