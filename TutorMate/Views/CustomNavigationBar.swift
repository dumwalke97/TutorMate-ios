import SwiftUI
import FirebaseAuth

struct CustomNavigationBar: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared

    var body: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.resetApp()
            } label: {
                Text("TutorMate")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .tracking(0.3)
                    .foregroundColor(.white)
            }

            Spacer(minLength: 8)

            if let user = firebaseManager.currentUser {
                Text(user.displayName ?? user.email ?? "User")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)

                Menu {
                    Button(action: { viewModel.resetApp() }) {
                        Label("Home", systemImage: "house")
                    }
                    Button(action: { viewModel.showFolders() }) {
                        Label("My Folders", systemImage: "folder")
                    }
                    Button(role: .destructive, action: { viewModel.signOut() }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(7)
                        .background(Circle().fill(Color.white.opacity(0.16)))
                }
            } else {
                Button {
                    viewModel.showLoginModal = true
                } label: {
                    Text("Log In")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }

                Button {
                    viewModel.showLoginModal = true
                } label: {
                    Text("Sign Up")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.tmNavy)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.tmNavy)
        .clipShape(Capsule())
    }
}
