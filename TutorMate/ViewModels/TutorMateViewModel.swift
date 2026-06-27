import SwiftUI
import PhotosUI
import FirebaseAuth
internal import Combine


class TutorMateViewModel: ObservableObject {
    
    // State
    @Published var currentState: AppState = .upload
    @Published var imageDataArray: [ImageData] = []
    @Published var quizData: [QuizQuestion] = []
    @Published var userAnswers: [Int: UserAnswer] = [:]
    @Published var currentQuestionIndex = 0
    @Published var score = 0
    
    // UI State
    @Published var progress: Double = 0
    @Published var loadingText = "Loading..."
    @Published var feedbackText: String? = nil
    @Published var isLastAnswerCorrect = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showLoginModal = false
    
    // Input
    @Published var customPrompt = ""
    @Published var questionCount = 10
    
    // Folders
    @Published var selectedFolderId: String? = nil
    @Published var folderItems: [FolderItem] = []
    @Published var selectedItemIds: Set<String> = []
    
    // Assignment
    @Published var assignmentFeedback = ""
    
    private var progressTimer: Timer?
    
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < quizData.count else { return nil }
        return quizData[currentQuestionIndex]
    }
    
    var scoreMessage: String {
        let percentage = Double(score) / Double(quizData.count) * 100
        if percentage >= 80 {
            return "Great job! You aced it!"
        } else if percentage >= 50 {
            return "Good effort! Keep practicing."
        } else {
            return "Don't worry, try again!"
        }
    }
    
    // MARK: - Image Handling
    
    func handleImageSelection(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    if let processed = ImageProcessor.resizeImage(image, maxSize: 800, quality: 0.7) {
                        let imageData = ImageData(
                            id: UUID().uuidString,
                            thumbnailImage: image,
                            apiData: APIImageData(
                                mimeType: "image/jpeg",
                                data: processed.1,
                                text: nil
                            )
                        )
                        imageDataArray.append(imageData)
                    }
                }
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard index < imageDataArray.count else { return }
        imageDataArray.remove(at: index)
    }
    
    // MARK: - Quiz Generation
    
    func generateQuiz() {
        guard !imageDataArray.isEmpty || !customPrompt.isEmpty else {
            showAlertMessage(title: "Error", message: "Please upload an image or enter a topic.")
            return
        }
        
        currentState = .loading
        loadingText = "Generating Quiz..."
        startProgressBar()
        
        Task {
            do {
                let payload = buildQuizPayload()
                let response = try await NetworkManager.shared.generateQuiz(payload: payload)
                
                // Shuffle options for each question
                var shuffledQuestions = response.questions
                for i in 0..<shuffledQuestions.count {
                    shuffledQuestions[i] = QuizQuestion(
                        question: shuffledQuestions[i].question,
                        options: shuffledQuestions[i].options.shuffled(),
                        answer: shuffledQuestions[i].answer
                    )
                }
                
                quizData = shuffledQuestions
                userAnswers = [:]
                currentQuestionIndex = 0
                score = 0
                
                completeProgressBar()
                currentState = .quiz
            } catch {
                showAlertMessage(title: "Error", message: "Failed to generate quiz: \(error.localizedDescription)")
                resetApp()
            }
        }
    }
    
    private func buildQuizPayload() -> [String: Any] {
        var parts: [[String: Any]] = []
        
        // Add custom prompt or default text
        let promptText = customPrompt.isEmpty ? "Analyze the content of the following image(s)." : customPrompt
        parts.append(["text": "\(promptText) Generate a practice quiz with \(questionCount) questions."])
        
        // Add images
        for imageData in imageDataArray {
            if let data = imageData.apiData.data {
                parts.append([
                    "inlineData": [
                        "mimeType": imageData.apiData.mimeType,
                        "data": data
                    ]
                ])
            }
        }
        
        return [
            "contents": [
                ["parts": parts]
            ],
            "systemInstruction": [
                "parts": [["text": Self.quizSystemPrompt]]
            ]
        ]
    }

    static let quizSystemPrompt = """
    You are an expert quiz creator. Your task is to analyze the provided image(s) and/or text to understand the topics and concepts present. Based on this analysis, create a set of multiple-choice questions. The output must be a valid JSON object following this specific schema:
    {"questions": [{"question": "...", "options": ["...", "...", "...", "..."], "answer": "..."}]}.
    IMPORTANT: Each question MUST have exactly 4 options. The 'answer' field must exactly match one of the strings in the 'options' array. All text should be plain text, without special formatting like Markdown or LaTeX.

    STYLE: The questions must be derived directly from the provided content. However, phrase them as standalone questions. Do NOT use phrases like "In the image", "According to the text", or "As shown in the file". Respond ONLY with the JSON object and nothing else.

    CRITICAL: The 'answer' field is MANDATORY for every question. It must be an exact string match to one of the options provided.
    """

    // MARK: - Folder Quiz & Upload

    func generateQuizFromFolder() {
        let items = folderItems.filter { selectedItemIds.contains($0.id) }
        guard !items.isEmpty else {
            showAlertMessage(title: "Error", message: "Please select at least one item.")
            return
        }

        currentState = .loading
        loadingText = "Generating Quiz..."
        startProgressBar()

        Task {
            do {
                var parts: [[String: Any]] = [
                    ["text": "Analyze the content of the following image(s). Generate a practice quiz with \(questionCount) questions."]
                ]

                for item in items {
                    guard let url = URL(string: item.url) else { continue }
                    let (data, _) = try await URLSession.shared.data(from: url)
                    parts.append([
                        "inlineData": [
                            "mimeType": item.mimeType,
                            "data": data.base64EncodedString()
                        ]
                    ])
                }

                let payload: [String: Any] = [
                    "contents": [["parts": parts]],
                    "systemInstruction": ["parts": [["text": Self.quizSystemPrompt]]]
                ]

                let response = try await NetworkManager.shared.generateQuiz(payload: payload)

                var shuffledQuestions = response.questions
                for i in 0..<shuffledQuestions.count {
                    shuffledQuestions[i] = QuizQuestion(
                        question: shuffledQuestions[i].question,
                        options: shuffledQuestions[i].options.shuffled(),
                        answer: shuffledQuestions[i].answer
                    )
                }

                quizData = shuffledQuestions
                userAnswers = [:]
                currentQuestionIndex = 0
                score = 0
                selectedItemIds = []

                completeProgressBar()
                currentState = .quiz
            } catch {
                showAlertMessage(title: "Error", message: "Failed to generate quiz: \(error.localizedDescription)")
                completeProgressBar()
                currentState = .folderContents
            }
        }
    }

    func uploadToCurrentFolder(_ items: [PhotosPickerItem]) {
        guard let userId = Auth.auth().currentUser?.uid,
              let folderId = selectedFolderId else { return }

        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let processed = ImageProcessor.resizeImage(image, maxSize: 800, quality: 0.7),
                   let jpegData = processed.0 {
                    try? await FirebaseManager.shared.uploadImage(
                        userId: userId,
                        folderId: folderId,
                        imageData: jpegData,
                        mimeType: "image/jpeg"
                    )
                }
            }

            if let updated = try? await FirebaseManager.shared.getFolderItems(userId: userId, folderId: folderId) {
                folderItems = updated
            }
        }
    }
    
    // MARK: - Quiz Navigation
    
    func handleAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        
        let isCorrect = answer == question.answer
        userAnswers[currentQuestionIndex] = UserAnswer(questionIndex: currentQuestionIndex, answer: answer)
        
        if isCorrect {
            score += 1
            feedbackText = "Correct!"
            isLastAnswerCorrect = true
        } else {
            feedbackText = "Incorrect. The correct answer was: \(question.answer)"
            isLastAnswerCorrect = false
        }
    }
    
    func nextQuestion() {
        feedbackText = nil
        currentQuestionIndex += 1
        
        if currentQuestionIndex >= quizData.count {
            showResults()
        }
    }
    
    func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
        feedbackText = nil
    }
    
    func showResults() {
        currentState = .results
    }
    
    func reviewAnswers() {
        currentState = .review
    }
    
    func retakeQuiz() {
        userAnswers = [:]
        currentQuestionIndex = 0
        score = 0
        feedbackText = nil
        generateQuiz()
    }
    
    func showQuitConfirmation() {
        // In a real app, show a confirmation dialog
        resetApp()
    }
    
    // MARK: - Assignment Checking
    
    func checkAssignment() {
        guard !imageDataArray.isEmpty else {
            showAlertMessage(title: "Error", message: "Please upload at least one image.")
            return
        }
        
        currentState = .loading
        loadingText = "Checking Assignment..."
        startProgressBar()
        
        Task {
            do {
                let payload = buildAssignmentPayload()
                let response = try await NetworkManager.shared.checkAssignment(payload: payload)
                
                assignmentFeedback = response
                completeProgressBar()
                currentState = .assignmentResults
            } catch {
                showAlertMessage(title: "Error", message: "Failed to check assignment: \(error.localizedDescription)")
                resetApp()
            }
        }
    }
    
    private func buildAssignmentPayload() -> [String: Any] {
        var parts: [[String: Any]] = [
            ["text": "Please check this assignment and provide the correct answers with explanations."]
        ]
        
        for imageData in imageDataArray {
            if let data = imageData.apiData.data {
                parts.append([
                    "inlineData": [
                        "mimeType": imageData.apiData.mimeType,
                        "data": data
                    ]
                ])
            }
        }
        
        let systemPrompt = """
        You are a helpful and encouraging tutor. Your task is to analyze the provided image(s) and/or text content. For each distinct question or topic you identify, provide a detailed analysis.
        
        Format your response using Markdown. For each question, create a single list item that contains the question, the student's visible answer, the correct answer, and an explanation.
        
        CRITICAL RULES:
        1. Do NOT use any special formatting characters for math, like '$'.
        2. Respond ONLY with plain text and Markdown lists.
        3. Keep explanations concise and clear.
        """
        
        return [
            "contents": [
                ["parts": parts]
            ],
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ]
        ]
    }
    
    // MARK: - Folders
    
    func showFolders() {
        currentState = .folders
        Task {
            if let userId = Auth.auth().currentUser?.uid {
                await FirebaseManager.shared.loadFolders(userId: userId)
            }
        }
    }
    
    func openFolder(_ folderId: String) {
        selectedFolderId = folderId
        selectedItemIds = []
        currentState = .loading
        loadingText = "Loading folder..."
        
        Task {
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    folderItems = try await FirebaseManager.shared.getFolderItems(
                        userId: userId,
                        folderId: folderId
                    )
                    currentState = .folderContents
                } catch {
                    showAlertMessage(title: "Error", message: "Failed to load folder contents.")
                    currentState = .folders
                }
            }
        }
    }
    
    func toggleItemSelection(_ itemId: String) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
    }
    
    func deleteSelectedItems() {
        guard let userId = Auth.auth().currentUser?.uid,
              let folderId = selectedFolderId else { return }
        
        Task {
            for itemId in selectedItemIds {
                try? await FirebaseManager.shared.deleteItem(
                    userId: userId,
                    folderId: folderId,
                    itemId: itemId
                )
            }
            selectedItemIds.removeAll()
            openFolder(folderId)
        }
    }
    
    // MARK: - Auth
    
    func signOut() {
        do {
            try FirebaseManager.shared.signOut()
            resetApp()
        } catch {
            showAlertMessage(title: "Error", message: "Failed to sign out.")
        }
    }
    
    // MARK: - Utilities
    
    func resetApp() {
        currentState = .upload
        imageDataArray = []
        quizData = []
        userAnswers = [:]
        currentQuestionIndex = 0
        score = 0
        customPrompt = ""
        questionCount = 10
        feedbackText = nil
        selectedFolderId = nil
        selectedItemIds = []
        folderItems = []
        assignmentFeedback = ""
        stopProgressBar()
    }
    
    private func startProgressBar() {
        progress = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.progress < 0.6 {
                self.progress += Double.random(in: 0...0.05)
            } else if self.progress < 0.9 {
                self.progress += Double.random(in: 0...0.02)
            } else if self.progress < 0.99 {
                self.progress += 0.001
            }
            self.progress = min(self.progress, 0.99)
        }
    }
    
    private func completeProgressBar() {
        progress = 1.0
        stopProgressBar()
    }
    
    private func stopProgressBar() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func showAlertMessage(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
