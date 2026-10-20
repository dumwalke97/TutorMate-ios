import SwiftUI
import FirebaseAuth
import StoreKit

struct CustomNavigationBar: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @ObservedObject var store = StoreManager.shared
    @State private var showChangeEmailAlert = false
    @State private var newEmail = ""
    @State private var showManageSubscriptions = false
    @State private var showFoundingMemberAlert = false
    @State private var showWebManagedAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false

    /// True for anyone with premium access, however they got it - a real
    /// StoreKit purchase, a Firestore-mirrored subscription (Stripe on the
    /// web, or Apple on another device), or a grandfathered account.
    private var hasAnySubscription: Bool {
        store.isSubscribed || firebaseManager.hasRemoteSubscription || firebaseManager.isGrandfathered
    }

    private var isGrandfatheredSource: Bool {
        firebaseManager.isGrandfathered || firebaseManager.remoteSubscriptionSource == "grandfathered"
    }

    /// Routes "Subscription" to whichever management surface actually
    /// applies, mirroring the web app's identical branching.
    ///
    /// The last branch is deliberately an `else` rather than a test for
    /// "apple": `hasAnySubscription` shows this item for anyone with
    /// premium access, so every one of them has to land somewhere. An
    /// Apple subscription bought on another device reaches here with
    /// `store.isSubscribed` still false, because StoreKit resolves
    /// `Transaction.currentEntitlements` asynchronously while the
    /// Firestore listener answers immediately. Apple does the billing in
    /// that case either way, so its own sheet is the honest destination.
    private func manageSubscriptionTapped() {
        if store.isSubscribed {
            showManageSubscriptions = true
        } else if isGrandfatheredSource {
            showFoundingMemberAlert = true
        } else if firebaseManager.remoteSubscriptionSource == "stripe" {
            showWebManagedAlert = true
        } else {
            showManageSubscriptions = true
        }
    }

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

            // Anonymous sessions exist only to authenticate API calls; the
            // UI treats them as logged out.
            if let user = firebaseManager.currentUser, !user.isAnonymous {
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
                    if hasAnySubscription {
                        Button(action: manageSubscriptionTapped) {
                            Label("Subscription", systemImage: "creditcard")
                        }
                    }
                    Divider()
                    Button(role: .destructive, action: { viewModel.signOut() }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                    Button(role: .destructive, action: { showDeleteAccountAlert = true }) {
                        Label("Delete Account", systemImage: "trash")
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
                    Text("Upgrade")
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

                // Subscriptions belong to the Apple Account, not the app
                // login, so subscribers need this menu even when logged out.
                if store.isSubscribed {
                    Menu {
                        Button(action: { showManageSubscriptions = true }) {
                            Label("Subscription", systemImage: "creditcard")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tmNavy)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.tmFieldFill))
                    }
                }
            }
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .alert("You're a founding member!", isPresented: $showFoundingMemberAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("As one of TutorMate's original beta testers, you've been granted a free lifetime subscription, no payment required, ever. Thank you for helping us build this.")
        }
        .alert("Managed on the Web", isPresented: $showWebManagedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your TutorMate Premium subscription was purchased on tutormate.ai, so billing is handled there. To manage or cancel it, visit tutormate.ai and log in with the same account.")
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) { deleteAccount() }
        } message: {
            Text("This permanently deletes your account, folders, and uploaded images. It cannot be undone.\n\nNote: an active subscription is not canceled by deleting your account — manage it in Settings > Apple Account > Subscriptions.")
        }
        .disabled(isDeletingAccount)
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

    private func deleteAccount() {
        isDeletingAccount = true
        Task {
            do {
                try await FirebaseManager.shared.deleteAccount()
                isDeletingAccount = false
                viewModel.resetApp()
                viewModel.showAlertMessage(
                    title: "Account Deleted",
                    message: "Your account and all associated data have been deleted."
                )
            } catch {
                isDeletingAccount = false
                viewModel.showAlertMessage(title: "Error", message: FirebaseManager.friendlyAuthError(error))
            }
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
