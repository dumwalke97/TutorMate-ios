import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: TutorMateViewModel

    var body: some View {
        VStack(spacing: 18) {
            header

            if let question = viewModel.currentQuestion {
                VStack(alignment: .leading, spacing: 14) {
                    Text(question.question)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.tmInk)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
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
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tmCard)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)
            }

            if let feedback = viewModel.feedbackText {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isLastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(feedback)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(viewModel.isLastAnswerCorrect ? Color.green : Color.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background((viewModel.isLastAnswerCorrect ? Color.green : Color.red).opacity(0.10))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.userAnswers[viewModel.currentQuestionIndex] != nil {
                Button(action: { viewModel.nextQuestion() }) {
                    Text(viewModel.currentQuestionIndex == viewModel.quizData.count - 1 ? "Finish Quiz" : "Next Question")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(Color.tmNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if viewModel.currentQuestionIndex > 0 {
                Button(action: { viewModel.previousQuestion() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tmNavy)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.tmFieldFill))
                }
            } else {
                Color.clear.frame(width: 34, height: 34)
            }

            VStack(spacing: 2) {
                Text("Quiz Time")
                    .font(.headline)
                    .foregroundColor(.tmInk)
                Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.quizData.count)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button(action: { viewModel.showQuitConfirmation() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tmNavy)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.tmFieldFill))
            }
        }
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
            HStack(spacing: 10) {
                Text(option)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isAnswered)
    }

    private var backgroundColor: Color {
        guard isAnswered else { return .tmFieldFill }
        if isCorrect { return Color.green.opacity(0.15) }
        if isSelected { return Color.red.opacity(0.15) }
        return .tmFieldFill
    }

    private var textColor: Color {
        guard isAnswered else { return .tmInk }
        if isCorrect { return Color.green }
        if isSelected { return Color.red }
        return .tmInk.opacity(0.6)
    }

    private var trailingIcon: String? {
        guard isAnswered else { return nil }
        if isCorrect { return "checkmark.circle.fill" }
        if isSelected { return "xmark.circle.fill" }
        return nil
    }
}
