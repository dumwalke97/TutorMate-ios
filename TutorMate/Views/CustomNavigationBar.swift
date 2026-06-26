import SwiftUI
import FirebaseAuth

struct CustomNavigationBar: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Button {
                viewModel.resetApp()
            } label: {
                Image("TutorMateMark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 6)

            if let user = firebaseManager.currentUser {
                Text(user.displayName ?? user.email ?? "User")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.tmInk.opacity(0.55))
                    .lineLimit(1)

                Menu {
                    Button(action: { viewModel.resetApp() }) {
                        Label("Home", systemImage: "house")
                    }
                    Button(role: .destructive, action: { viewModel.signOut() }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tmNavy)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.tmFieldFill))
                }
            } else {
                Button {
                    viewModel.showLoginModal = true
                } label: {
                    Text("Log In")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.tmNavy)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }

                Button {
                    viewModel.showLoginModal = true
                } label: {
                    Text("Sign Up")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.tmNavy)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
