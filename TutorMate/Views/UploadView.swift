import SwiftUI
import PhotosUI

struct UploadView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false

    private let questionOptions = [5, 10, 20, 30, 40, 50]

    private var hasImages: Bool { !viewModel.imageDataArray.isEmpty }

    var body: some View {
        VStack(spacing: 32) {
            heroOval
            quizCard
        }
        .padding(.top, 8)
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

                Text("Snap an assignment or build a quiz on any topic.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if hasImages {
                thumbnailStrip
            }

            VStack(spacing: 10) {
                addImagesButton

                if hasImages {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of questions")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.78))

                        HStack(spacing: 8) {
                            ForEach(questionOptions, id: \.self) { count in
                                heroQuestionChip(count)
                            }
                        }
                    }
                    .padding(.top, 4)

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
        Button {
            showSourceDialog = true
        } label: {
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
        .confirmationDialog("Add Images / Files", isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button("Take Photo") { showCamera = true }
            Button("Photo Library") { showPhotoPicker = true }
            Button("Browse Files") { showFileImporter = true }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, matching: .images)
        .onChange(of: selectedItems) { newItems in
            viewModel.handleImageSelection(newItems)
            selectedItems = []
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                viewModel.addImage(image)
            }
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    viewModel.addImage(image)
                }
            }
        }
    }

    private func heroQuestionChip(_ count: Int) -> some View {
        let isSelected = viewModel.questionCount == count
        return Button {
            viewModel.questionCount = count
        } label: {
            Text("\(count)")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .tmNavy : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.white.opacity(0.16))
                .clipShape(Capsule())
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
