import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: TutorMateViewModel

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) {
                Text("Quiz Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.tmInk)

                Text("\(viewModel.score) / \(viewModel.quizData.count)")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(.tmNavy)
                    .tracking(-1)

                Text(viewModel.scoreMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(Color.tmCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)

            VStack(spacing: 10) {
                Button(action: { viewModel.reviewAnswers() }) {
                    Text("Review Answers")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(Color.tmNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: { viewModel.retakeQuiz() }) {
                    Text("Retake Quiz")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.tmNavy)
                        .background(Color.tmNavy.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: { viewModel.resetApp() }) {
                    Text("Start Over")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                }
            }
        }
    }
}
