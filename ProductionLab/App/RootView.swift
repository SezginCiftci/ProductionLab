import SwiftUI

/// Giriş yapılmışsa sekmeleri, yapılmamışsa Login ekranını gösterir.
struct RootView: View {
    let container: AppDependencyContainer

    var body: some View {
        if container.authService.isLoggedIn {
            // .id: veri seti değişince sekmeler ve ViewModel'ler yeni repository'lerle sıfırdan kurulur.
            MainTabView(container: container)
                .id(container.dataSet)
        } else {
            LoginView(viewModel: container.makeLoginViewModel())
        }
    }
}

struct MainTabView: View {
    let container: AppDependencyContainer

    // ViewModel'ler @State içinde tutulur; böylece ekran yeniden çizildiğinde kaybolmazlar.
    @State private var dashboardViewModel: DashboardViewModel
    @State private var holdingsViewModel: HoldingsViewModel
    @State private var activityViewModel: ActivityViewModel
    @State private var settingsViewModel: SettingsViewModel

    init(container: AppDependencyContainer) {
        self.container = container
        _dashboardViewModel = State(initialValue: container.makeDashboardViewModel())
        _holdingsViewModel = State(initialValue: container.makeHoldingsViewModel())
        _activityViewModel = State(initialValue: container.makeActivityViewModel())
        _settingsViewModel = State(initialValue: container.makeSettingsViewModel())
    }

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem { Label("Dashboard", systemImage: "chart.pie") }
            HoldingsView(viewModel: holdingsViewModel)
                .tabItem { Label("Holdings", systemImage: "list.bullet.rectangle") }
            ActivityView(viewModel: activityViewModel)
                .tabItem { Label("Activity", systemImage: "clock.arrow.circlepath") }
            SettingsView(viewModel: settingsViewModel, container: container)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
