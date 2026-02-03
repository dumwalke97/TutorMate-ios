import SwiftUI
struct FolderContentsView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { viewModel.currentState = .folders }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                Spacer()
            }
            
            if viewModel.folderItems.isEmpty {
                Text("This folder is empty")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(viewModel.folderItems) { item in
                            FolderItemView(
                                item: item,
                                isSelected: viewModel.selectedItemIds.contains(item.id),
                                onTap: { viewModel.toggleItemSelection(item.id) }
                            )
                        }
                    }
                }
            }
            
            if !viewModel.selectedItemIds.isEmpty {
                HStack(spacing: 12) {
                    Button(action: { viewModel.deleteSelectedItems() }) {
                        Text("Delete")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

struct FolderItemView: View {
    let item: FolderItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                AsyncImage(url: URL(string: item.url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: item.createdAt)
    }
}
