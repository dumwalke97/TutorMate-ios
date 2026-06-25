import SwiftUI

struct AssignmentResultsView: View {
    @ObservedObject var viewModel: TutorMateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button(action: { viewModel.resetApp() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tmNavy)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.tmFieldFill))
                }

                Text("Assignment Feedback")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.tmInk)
                    .lineLimit(1)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(.init(viewModel.assignmentFeedback))
                    .font(.body)
                    .foregroundColor(.tmInk)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tmCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)

            Button(action: { viewModel.resetApp() }) {
                Text("Start Over")
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
