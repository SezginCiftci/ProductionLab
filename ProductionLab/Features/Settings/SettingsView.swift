import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel
    let container: AppDependencyContainer

    var body: some View {
        NavigationStack {
            List {
                Section("Uygulama") {
                    LabeledContent("Version", value: viewModel.version)
                        .accessibilityIdentifier("settings.version")
                    LabeledContent("Build", value: viewModel.build)
                        .accessibilityIdentifier("settings.build")
                    LabeledContent("Configuration", value: viewModel.configuration)
                        .accessibilityIdentifier("settings.configuration")
                    LabeledContent("Ortam", value: viewModel.environment)
                        .accessibilityIdentifier("settings.environment")
                }

                // Diagnostics yalnızca Debug derlemesinde görünür.
                #if DEBUG
                Section("Geliştirici") {
                    NavigationLink("Diagnostics") {
                        DiagnosticsView(viewModel: container.makeDiagnosticsViewModel())
                    }
                    .accessibilityIdentifier("settings.diagnostics")
                }
                #endif

                Section {
                    Button("Çıkış yap", role: .destructive) {
                        viewModel.logout()
                    }
                    .accessibilityIdentifier("settings.logout")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
