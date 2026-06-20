import SwiftUI
import PhotosUI

struct UploadView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @State private var selectedItems: [PhotosPickerItem] = []

    private let questionOptions = [5, 10, 15, 20, 25, 30]

    var body: some View {
        VStack(spacing: 18) {
            heroOval
            quizCard
        }
    }

    private var heroOval: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Learn smarter.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .tracking(-0.2)
                    .foregroundColor(.white)

                Text("Snap a worksheet or build a quiz on any topic.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !viewModel.imageDataArray.isEmpty {
                thumbnailStrip
            }

            VStack(spacing: 10) {
                addImagesButton

                if !viewModel.imageDataArray.isEmpty {
                    Button(action: { viewModel.checkAssignment() }) {
                        Text("Check Assignment")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(20)
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
                Text(viewModel.imageDataArray.isEmpty ? "Add Images / Files" : "Add More Photos")
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
                Text("Generate Quiz")
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
