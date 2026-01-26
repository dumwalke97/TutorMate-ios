struct ReviewView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Review Answers")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Button("Back to Results") {
                    viewModel.showResults()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(8)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.quizData.indices, id: \.self) { index in
                        ReviewQuestionCard(
                            question: viewModel.quizData[index],
                            userAnswer: viewModel.userAnswers[index]?.answer ?? "Not Answered",
                            questionNumber: index + 1
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct ReviewQuestionCard: View {
    let question: QuizQuestion
    let userAnswer: String
    let questionNumber: Int
    
    var isCorrect: Bool {
        userAnswer == question.answer
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Q\(questionNumber): \(question.question)")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Answer: \(userAnswer)")
                        .font(.system(size: 14))
                }
            }
            .padding()
            .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(8)
            
            if !isCorrect {
                Text("Correct Answer: \(question.answer)")
                    .font(.system(size: 14))
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}