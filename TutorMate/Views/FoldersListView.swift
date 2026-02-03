import SwiftUI
import FirebaseAuth
struct FoldersListView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @State private var showNewFolderDialog = false
    @State private var newFolderName = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { viewModel.resetApp() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Text("My Folders")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                Color.clear.frame(width: 60)
            }
            
            if firebaseManager.folders.isEmpty {
                Text("You don't have any folders yet.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(firebaseManager.folders) { folder in
                        Button(action: { viewModel.openFolder(folder.id) }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(red: 0.31, green: 0.36, blue: 0.63).opacity(0.7))
                                
                                Text(folder.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.31, green: 0.36, blue: 0.63))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            Button(action: { showNewFolderDialog = true }) {
                Text("New Folder")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }
        }
        .padding()
        .alert("New Folder", isPresented: $showNewFolderDialog) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createFolder()
            }
        }
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            try? await FirebaseManager.shared.createFolder(userId: userId, name: newFolderName)
            newFolderName = ""
        }
    }
}
