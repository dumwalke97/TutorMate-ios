import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var showForgotPassword = false
    @State private var resetEmail = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.tmInk)
                        .multilineTextAlignment(.center)

                    Text(isSignUp
                         ? "Sign up to save quizzes and track your progress."
                         : "Log in to keep learning where you left off.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                formCard

                Button(action: { isSignUp.toggle() }) {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.secondary)
                        Text(isSignUp ? "Log In" : "Sign Up")
                            .foregroundColor(.tmNavy)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }

                if !isSignUp {
                    Button {
                        resetEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        showForgotPassword = true
                    } label: {
                        Text("Forgot password?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .underline()
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.tmCanvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 26, weight: .regular))
                            .foregroundColor(.tmInk.opacity(0.55))
                    }
                }
            }
            .toolbarBackground(Color.tmCanvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { isSignUp = viewModel.authStartAsSignUp }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email address", text: $resetEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) { }
            Button("Send Link") { handleForgotPassword(resetEmail) }
        } message: {
            Text("Enter your email and we'll send you a link to reset your password.")
        }
    }

    private var formCard: some View {
        VStack(spacing: 12) {
            TextField("Email address", text: $email)
                .font(.body)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.tmFieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            SecureField("Password", text: $password)
                .font(.body)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.tmFieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button(action: handleEmailAuth) {
                Text(isSignUp ? "Sign Up" : "Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundColor(.white)
                    .background(Color.tmNavy)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.top, 4)

            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.tmInk.opacity(0.12))
                    .frame(height: 1)
                Text("or")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.tmInk.opacity(0.12))
                    .frame(height: 1)
            }
            .padding(.vertical, 2)

            Button(action: handleGoogleAuth) {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 18))
                    Text("Continue with Google")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.tmInk)
                .background(Color.tmFieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.tmInk.opacity(0.10), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func handleEmailAuth() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedEmail) else {
            viewModel.showAlertMessage(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }

        if isSignUp && password.count < 6 {
            viewModel.showAlertMessage(title: "Weak Password", message: "Please choose a password with at least 6 characters.")
            return
        }

        Task {
            do {
                if isSignUp {
                    try await FirebaseManager.shared.signUpWithEmail(email: trimmedEmail, password: password)
                    dismiss()
                    viewModel.showAlertMessage(
                        title: "Verify Your Email",
                        message: "We sent a verification link to \(trimmedEmail). Please check your inbox to confirm your account."
                    )
                } else {
                    try await FirebaseManager.shared.signInWithEmail(email: trimmedEmail, password: password)
                    dismiss()
                }
            } catch {
                viewModel.showAlertMessage(title: "Error", message: FirebaseManager.friendlyAuthError(error))
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func handleGoogleAuth() {
        Task {
            do {
                try await FirebaseManager.shared.signInWithGoogle()
                dismiss()
            } catch {
                viewModel.showAlertMessage(title: "Error", message: FirebaseManager.friendlyAuthError(error))
            }
        }
    }

    private func handleForgotPassword(_ address: String) {
        let trimmedEmail = address.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(trimmedEmail) else {
            viewModel.showAlertMessage(
                title: "Invalid Email",
                message: "Please enter a valid email address to receive a reset link."
            )
            return
        }

        Task {
            do {
                try await FirebaseManager.shared.sendPasswordReset(email: trimmedEmail)
                dismiss()
                viewModel.showAlertMessage(
                    title: "Check Your Email",
                    message: "We sent a password reset link to \(trimmedEmail)."
                )
            } catch {
                viewModel.showAlertMessage(title: "Error", message: FirebaseManager.friendlyAuthError(error))
            }
        }
    }
}
