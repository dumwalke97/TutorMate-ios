import SwiftUI

struct ReviewView: View {
    @ObservedObject var viewModel: TutorMateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button(action: { viewModel.showResults() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tmNavy)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.tmFieldFill))
                }

                Text("Review Answers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.tmInk)
                    .lineLimit(1)

                Spacer()
            }

            VStack(spacing: 12) {
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
            HStack(alignment: .top, spacing: 10) {
                Text("Q\(questionNumber)")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.tmNavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.tmNavy.opacity(0.10))
                    .clipShape(Capsule())

                Text(question.question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.tmInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? Color.green : Color.red)
                    .font(.system(size: 16, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your answer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(userAnswer)
                        .font(.subheadline)
                        .foregroundColor(.tmInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background((isCorrect ? Color.green : Color.red).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !isCorrect {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green)
                        .font(.system(size: 16, weight: .semibold))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Correct answer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(question.answer)
                            .font(.subheadline)
                            .foregroundColor(.tmInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
