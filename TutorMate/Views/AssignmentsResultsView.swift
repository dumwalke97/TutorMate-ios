import SwiftUI
struct AssignmentResultsView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Assignment Feedback")
                .font(.system(size: 24, weight: .bold))
            
            ScrollView {
                Text(viewModel.assignmentFeedback)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 400)
            
            Button(action: { viewModel.resetApp() }) {
                Text("Start Over")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
