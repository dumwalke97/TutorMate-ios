import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true

    var body: some View {
        ZStack(alignment: .top) {
            Color.tmCanvas
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tmNavy)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.tmFieldFill))
                    }
                }

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
                .padding(.top, 4)

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

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
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
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func handleEmailAuth() {
        Task {
            do {
                if isSignUp {
                    try await FirebaseManager.shared.signUpWithEmail(email: email, password: password)
                } else {
                    try await FirebaseManager.shared.signInWithEmail(email: email, password: password)
                }
                dismiss()
            } catch {
                viewModel.showAlertMessage(title: "Error", message: error.localizedDescription)
            }
        }
    }
}
