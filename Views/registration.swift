import SwiftUI

struct RegisterView: View {

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 5) {

                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)

                        Text("Create Account")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Join Physical Book Tracker")
                            .foregroundColor(.white.opacity(0.8))

                        VStack(spacing: 18) {

                            TextField("Full Name", text: $fullName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)

                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)

                            HStack {

                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField("Password", text: $password)
                                    }
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            HStack {

                                Group {
                                    if showConfirmPassword {
                                        TextField("Confirm Password", text: $confirmPassword)
                                    } else {
                                        SecureField("Confirm Password", text: $confirmPassword)
                                    }
                                }

                                Button {
                                    showConfirmPassword.toggle()
                                } label: {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            Button {

                            } label: {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(15)
                            }

                            HStack {
                                Rectangle()
                                    .frame(height: 1)

                                Text("OR")
                                    .foregroundColor(.gray)

                                Rectangle()
                                    .frame(height: 1)
                            }
                            .foregroundColor(.gray)

                            Button {

                            } label: {
                                HStack {

                                    Image(systemName: "globe")

                                    Text("Continue with Google")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                            }

                            Button {

                            } label: {
                                HStack {

                                    Image(systemName: "applelogo")

                                    Text("Continue with Apple")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(15)
                            }

                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(25)
                        .padding(.horizontal)

                        HStack {

                            Text("Already have an account?")
                                .foregroundColor(.white)

                            NavigationLink("Login") {
                                LoginView()
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)

                        }
                        .padding(.bottom, 30)

                    }
                    .padding(.top, 40)
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
