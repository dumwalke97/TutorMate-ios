import SwiftUI
struct LoginView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(isSignUp ? "Sign Up" : "Log In")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top)
                
                VStack(spacing: 16) {
                    TextField("Email address", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                    
                    Button(action: handleEmailAuth) {
                        Text(isSignUp ? "Sign Up" : "Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.31, green: 0.36, blue: 0.63))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .padding()
            }
            .padding()
        }
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
