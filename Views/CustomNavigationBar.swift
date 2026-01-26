struct CustomNavigationBar: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @State private var showMenu = false
    
    var body: some View {
        HStack {
            Spacer()
            
            if let user = firebaseManager.currentUser {
                HStack(spacing: 16) {
                    Text(user.displayName ?? user.email ?? "User")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
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
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Button("Log In") {
                        viewModel.showLoginModal = true
                    }
                    .foregroundColor(.white)
                    
                    Text("|")
                        .foregroundColor(.white)
                    
                    Button("Sign Up") {
                        viewModel.showLoginModal = true
                    }
                    .foregroundColor(.white)
                }
                .font(.system(size: 14, weight: .medium))
            }
        }
        .padding()
        .background(Color(red: 0.31, green: 0.36, blue: 0.63))
    }
}