import SwiftUI

struct FolderContentsView: View {
    @ObservedObject var viewModel: TutorMateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if viewModel.folderItems.isEmpty {
                emptyState
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(viewModel.folderItems) { item in
                        FolderItemView(
                            item: item,
                            isSelected: viewModel.selectedItemIds.contains(item.id),
                            onTap: { viewModel.toggleItemSelection(item.id) }
                        )
                    }
                }
            }

            if !viewModel.selectedItemIds.isEmpty {
                Button(action: { viewModel.deleteSelectedItems() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete \(viewModel.selectedItemIds.count) item\(viewModel.selectedItemIds.count == 1 ? "" : "s")")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.currentState = .folders }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tmNavy)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.tmFieldFill))
            }

            Text("Folder Contents")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.tmInk)
                .lineLimit(1)

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.tmNavy.opacity(0.4))

            Text("This folder is empty")
                .font(.headline)
                .foregroundColor(.tmInk)

            Text("Items you save will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

struct FolderItemView: View {
    let item: FolderItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                AsyncImage(url: URL(string: item.url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.tmNavy.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.tmFieldFill)
                }
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.tmNavy : Color.clear, lineWidth: 2.5)
                )

                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.tmCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.tmNavy.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: item.createdAt)
    }
}
