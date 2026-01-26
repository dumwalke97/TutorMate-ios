struct QuizView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                if viewModel.currentQuestionIndex > 0 {
                    Button(action: { viewModel.previousQuestion() }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("Quiz Time!")
                        .font(.system(size: 20, weight: .bold))
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.quizData.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Spacer for alignment
                if viewModel.currentQuestionIndex > 0 {
                    Color.clear.frame(width: 44)
                }
            }
            
            // Question
            if let question = viewModel.currentQuestion {
                VStack(alignment: .leading, spacing: 16) {
                    Text(question.question)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.bottom)
                    
                    // Options
                    ForEach(question.options.indices, id: \.self) { index in
                        QuizOptionButton(
                            option: question.options[index],
                            isCorrect: question.options[index] == question.answer,
                            isSelected: viewModel.userAnswers[viewModel.currentQuestionIndex]?.answer == question.options[index],
                            isAnswered: viewModel.userAnswers[viewModel.currentQuestionIndex] != nil,
                            action: {
                                viewModel.handleAnswer(question.options[index])
                            }
                        )
                    }
                }
            }
            
            // Feedback
            if let feedback = viewModel.feedbackText {
                Text(feedback)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.isLastAnswerCorrect ? .green : .red)
            }
            
            // Next Button
            if viewModel.userAnswers[viewModel.currentQuestionIndex] != nil {
                Button(action: { viewModel.nextQuestion() }) {
                    Text(viewModel.currentQuestionIndex == viewModel.quizData.count - 1 ? "Finish Quiz" : "Next Question")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Quit Button
            Button(action: { viewModel.showQuitConfirmation() }) {
                Text("Quit")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct QuizOptionButton: View {
    let option: String
    let isCorrect: Bool
    let isSelected: Bool
    let isAnswered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(backgroundColor)
                .foregroundColor(textColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2)
                )
                .cornerRadius(8)
        }
        .disabled(isAnswered)
    }
    
    private var backgroundColor: Color {
        if isAnswered {
            if isCorrect {
                return Color.green
            } else if isSelected {
                return Color.red
            }
        }
        return Color(UIColor.systemBackground)
    }
    
    private var textColor: Color {
        isAnswered && (isCorrect || isSelected) ? .white : .primary
    }
    
    private var borderColor: Color {
        if isAnswered {
            if isCorrect {
                return Color.green.opacity(0.8)
            } else if isSelected {
                return Color.red.opacity(0.8)
            }
        }
        return Color.gray.opacity(0.3)
    }
}