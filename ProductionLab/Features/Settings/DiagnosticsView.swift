import SwiftUI

struct DiagnosticsView: View {
    @State var viewModel: DiagnosticsViewModel

    var body: some View {
        List {
            Section("Mock API senaryosu") {
                ForEach(MockScenario.allCases, id: \.self) { scenario in
                    Button {
                        Task { await viewModel.select(scenario) }
                    } label: {
                        CheckmarkRow(title: scenario.title, isSelected: scenario == viewModel.scenario)
                    }
                    .accessibilityIdentifier("diagnostics.scenario.\(scenario.rawValue)")
                }
            }

            Section {
                ForEach(DataSet.allCases) { dataSet in
                    Button {
                        viewModel.select(dataSet)
                    } label: {
                        CheckmarkRow(title: dataSet.title, isSelected: dataSet == viewModel.dataSet)
                    }
                    .accessibilityIdentifier("diagnostics.dataSet.\(dataSet.rawValue)")
                }
            } header: {
                Text("Veri seti")
            } footer: {
                Text("Performans setleri bellekte ayrı bir veritabanında tutulur; normal veriniz değişmez. Seçimden sonra Dashboard açılır.")
            }

            Section("Aktif veritabanı") {
                LabeledContent("Varlık", value: "\(viewModel.holdingCount)")
                    .accessibilityIdentifier("diagnostics.holdingCount")
                LabeledContent("İşlem", value: "\(viewModel.transactionCount)")
                LabeledContent("Son yenileme",
                               value: viewModel.lastRefreshDate?.formatted(date: .abbreviated, time: .standard) ?? "Hiç")
            }

            if let message = viewModel.errorMessage {
                Section {
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Diagnostics")
        .task { await viewModel.load() }
    }
}

private struct CheckmarkRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
