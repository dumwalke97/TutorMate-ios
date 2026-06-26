import SwiftUI
import FirebaseAuth

struct FoldersListView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared
    @State private var showNewFolderDialog = false
    @State private var newFolderName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if firebaseManager.folders.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(firebaseManager.folders) { folder in
                        Button(action: { viewModel.openFolder(folder.id) }) {
                            folderTile(folder)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            newFolderButton
        }
        .alert("New Folder", isPresented: $showNewFolderDialog) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createFolder()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("My Folders")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.tmInk)
                .lineLimit(1)

            Spacer()
        }
    }

    private func folderTile(_ folder: Folder) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 26))
                .foregroundColor(.tmNavy)

            Text(folder.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.tmInk)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.tmNavy.opacity(0.4))

            Text("No folders yet")
                .font(.headline)
                .foregroundColor(.tmInk)

            Text("Create a folder to organize your saved quizzes and worksheets.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private var newFolderButton: some View {
        Button(action: { showNewFolderDialog = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("New Folder")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(Color.tmNavy)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
