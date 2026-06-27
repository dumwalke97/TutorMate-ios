import SwiftUI
import PhotosUI

struct UploadView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @State private var selectedItems: [PhotosPickerItem] = []

    private let questionOptions = [5, 10, 15, 20, 25, 30]

    private var hasImages: Bool { !viewModel.imageDataArray.isEmpty }

    var body: some View {
        VStack(spacing: 18) {
            heroOval
            quizCard
        }
    }

    // MARK: - Hero

    private var heroOval: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Learn smarter.")
                    .font(.title)
                    .fontWeight(.bold)
                    .tracking(-0.3)
                    .foregroundColor(.white)

                Text("Snap a worksheet or build a quiz on any topic.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasImages {
                thumbnailStrip
            }

            VStack(spacing: 10) {
                addImagesButton

                if hasImages {
                    HStack(spacing: 10) {
                        heroActionButton(
                            title: "Generate Quiz",
                            icon: "sparkles",
                            filled: true,
                            action: { viewModel.generateQuiz() }
                        )
                        heroActionButton(
                            title: "Check Assignment",
                            icon: "checkmark.circle",
                            filled: false,
                            action: { viewModel.checkAssignment() }
                        )
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tmNavy)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.imageDataArray.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: viewModel.imageDataArray[index].thumbnailImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Button(action: { viewModel.removeImage(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.tmNavy))
                        }
                        .offset(x: 5, y: -5)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var addImagesButton: some View {
        PhotosPicker(selection: $selectedItems, matching: .images) {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                Text(hasImages ? "Add More Photos" : "Add Images / Files")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.tmNavy)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .onChange(of: selectedItems) { newItems in
            viewModel.handleImageSelection(newItems)
        }
    }

    private func heroActionButton(
        title: String,
        icon: String,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(filled ? .tmNavy : .white)
            .background(filled ? Color.white : Color.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Quiz from a topic

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quiz from a topic")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.tmInk)

                Text("Type a subject and we'll build a quiz for it.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            TextField("e.g., 'US State Capitals'", text: $viewModel.customPrompt, axis: .vertical)
                .font(.body)
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.tmFieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("Number of questions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.tmInk.opacity(0.7))

                HStack(spacing: 8) {
                    ForEach(questionOptions, id: \.self) { count in
                        questionChip(count)
                    }
                }
            }

            Button(action: { viewModel.generateQuiz() }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Quiz")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .background(Color.tmNavy)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.06), radius: 18, x: 0, y: 8)
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
}
