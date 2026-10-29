import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authentication: AuthenticationStore
    @EnvironmentObject private var library: LibraryStore
    @State private var isRegistering = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        AppBrand(light: true).padding(.top, 42)
                        VStack(alignment: .leading, spacing: 18) {
                            Text(isRegistering ? "Create your account" : "Welcome back")
                                .font(.title2.bold())
                            Text(isRegistering ? "Save your library and reading activity securely." : "Sign in to pick up where your reading left off.")
                                .font(.subheadline).foregroundStyle(.secondary)
                            if isRegistering {
                                TextField("Full name", text: $name).textContentType(.name).textFieldStyle(.roundedBorder)
                            }
                            TextField("Email address", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                            SecureField("Password", text: $password).textContentType(isRegistering ? .newPassword : .password).textFieldStyle(.roundedBorder)
                            if isRegistering { SecureField("Confirm password", text: $confirmPassword).textFieldStyle(.roundedBorder) }
                            if let message = validationError ?? authentication.errorMessage {
                                Text(message).font(.footnote).foregroundStyle(.red)
                            }
                            Button(action: submit) {
                                HStack {
                                    if authentication.isLoading { ProgressView().tint(.white) }
                                    Text(isRegistering ? "Create account" : "Sign in").fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity).padding().background(.indigo, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                            }.disabled(authentication.isLoading || email.isEmpty || password.isEmpty)
                            HStack {
                                Text(isRegistering ? "Already have an account?" : "New to Chapter & Co.?").foregroundStyle(.secondary)
                                Button(isRegistering ? "Sign in" : "Create account") { isRegistering.toggle(); validationError = nil; authentication.errorMessage = nil }
                                    .fontWeight(.semibold)
                            }.frame(maxWidth: .infinity)
                        }
                        .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24)).padding(.horizontal, 22)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func submit() {
        validationError = nil
        guard email.contains("@") else { validationError = "Enter a valid email address."; return }
        if isRegistering {
            guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { validationError = "Enter your name."; return }
            guard password.count >= 6 else { validationError = "Use a password with at least 6 characters."; return }
            guard password == confirmPassword else { validationError = "The passwords do not match."; return }
            Task { await authentication.register(name: name, email: email, password: password) }
        } else {
            Task { await authentication.signIn(email: email, password: password) }
        }
    }
}
