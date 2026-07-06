import SwiftUI
import FirebaseAuth

struct CustomNavigationBar: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @State private var showChangeEmailAlert = false
    @State private var newEmail = ""

    var body: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.resetApp()
            } label: {
                Image("TutorMateMark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 6)

            if let user = firebaseManager.currentUser {
                Text(user.displayName ?? user.email ?? "User")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.tmInk.opacity(0.55))
                    .lineLimit(1)

                Menu {
                    Button(action: { viewModel.resetApp() }) {
                        Label("Home", systemImage: "house")
                    }
                    if firebaseManager.isPasswordUser {
                        Button(action: { showChangeEmailAlert = true }) {
                            Label("Change Email", systemImage: "envelope")
                        }
                        Button(action: sendPasswordReset) {
                            Label("Reset Password", systemImage: "key")
                        }
                    }
                    Button(role: .destructive, action: { viewModel.signOut() }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tmNavy)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.tmFieldFill))
                }
            } else {
                Button {
                    viewModel.authStartAsSignUp = false
                    viewModel.showLoginModal = true
                } label: {
                    Text("Log In")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.tmNavy)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }

                Button {
                    viewModel.showPaywall = true
                } label: {
                    Text("Sign Up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.tmNavy)
                        .clipShape(Capsule())
                }
            }
        }
        .alert("Change Email", isPresented: $showChangeEmailAlert) {
            TextField("New email address", text: $newEmail)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) { newEmail = "" }
            Button("Send Link") { changeEmail() }
        } message: {
            Text("Enter your new email address. We'll send a confirmation link there — your email changes once you click it.")
        }
    }

    private func sendPasswordReset() {
        guard let email = firebaseManager.currentUser?.email else { return }
        Task {
            do {
                try await FirebaseManager.shared.sendPasswordReset(email: email)
                viewModel.showAlertMessage(
                    title: "Check Your Email",
                    message: "We sent a password reset link to \(email)."
                )
            } catch {
                viewModel.showAlertMessage(title: "Error", message: FirebaseManager.friendlyAuthError(error))
            }
        }
    }

    private func changeEmail() {
        let trimmed = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        newEmail = ""
        guard !trimmed.isEmpty else { return }
        Task {
            do {
                try await FirebaseManager.shared.updateEmail(to: trimmed)
                viewModel.showAlertMessage(
                    title: "Confirm New Email",
                    message: "We sent a confirmation link to \(trimmed). Your email will update once you click it."
                )
            } catch {
                viewModel.showAlertMessage(title: "Error", message: FirebaseManager.friendlyAuthError(error))
            }
        }
    }
}
