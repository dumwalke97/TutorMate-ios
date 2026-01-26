struct ResultsView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Quiz Complete!")
                .font(.system(size: 28, weight: .bold))
            
            Text("\(viewModel.score) / \(viewModel.quizData.count)")
                .font(.system(size: 48, weight: .heavy))
                .foregroundColor(.blue)
            
            Text(viewModel.scoreMessage)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button(action: { viewModel.reviewAnswers() }) {
                    Text("Review Answers")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { viewModel.retakeQuiz() }) {
                    Text("Retake Quiz")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.31, green: 0.36, blue: 0.63))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { viewModel.resetApp() }) {
                    Text("Start Over")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(32)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
