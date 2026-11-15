import SwiftUI

struct LoginView: View {
    @State var viewModel: LoginViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Kullanıcı adı", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("login.username")
                    SecureField("Şifre", text: $viewModel.password)
                        .accessibilityIdentifier("login.password")
                } footer: {
                    Text("Eğitim hesabı: demo / demo123")
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("login.error")
                }

                Button {
                    Task { await viewModel.login() }
                } label: {
                    HStack {
                        Text("Giriş yap")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .accessibilityIdentifier("login.loading")
                        }
                    }
                }
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("login.submit")
            }
            .navigationTitle("ProductionLab")
        }
    }
}
