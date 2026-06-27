import SwiftUI
import PhotosUI

struct FolderContentsView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @State private var selectedItems: [PhotosPickerItem] = []

    private let questionOptions = [5, 10, 15, 20, 30, 50, 75, 100]

    private var selectedCount: Int { viewModel.selectedItemIds.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            uploadButton

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

            if selectedCount > 0 {
                actionButtons
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.currentState = .folders }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.tmNavy)
                    .frame(width: 44, height: 44)
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

    private var uploadButton: some View {
        PhotosPicker(selection: $selectedItems, matching: .images) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add to Folder")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(Color.tmNavy)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .onChange(of: selectedItems) { newItems in
            viewModel.uploadToCurrentFolder(newItems)
            selectedItems = []
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Number of questions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.tmInk.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                    spacing: 8
                ) {
                    ForEach(questionOptions, id: \.self) { count in
                        questionChip(count)
                    }
                }
            }

            Button(action: { viewModel.generateQuizFromFolder() }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Quiz")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.white)
                .background(Color.tmGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button(action: { viewModel.deleteSelectedItems() }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Delete \(selectedCount) item\(selectedCount == 1 ? "" : "s")")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(.red)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func questionChip(_ count: Int) -> some View {
        let isSelected = viewModel.questionCount == count
        return Button {
            viewModel.questionCount = count
        } label: {
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .tmNavy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.tmNavy : Color.tmFieldFill)
                .clipShape(Capsule())
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

            Text("Tap \u{201C}Add to Folder\u{201D} to upload your first item.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
                ZStack(alignment: .topTrailing) {
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

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.tmNavy)
                            .background(Circle().fill(Color.white))
                            .padding(6)
                    }
                }

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
