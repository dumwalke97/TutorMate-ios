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
                ForEach(Array(feedbackLines.enumerated()), id: \.offset) { _, line in
                    feedbackText(for: line)
                        .font(.body)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

    private var feedbackLines: [String] {
        viewModel.assignmentFeedback
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Colors the student's answer green or red based on the [CORRECT]/[INCORRECT]
    /// tag the model was instructed to include, stripping the tag from display.
    private func feedbackText(for line: String) -> Text {
        if let range = line.range(of: "[CORRECT]") {
            return coloredAnswerText(line: line, tagRange: range, color: .green)
        }
        if let range = line.range(of: "[INCORRECT]") {
            return coloredAnswerText(line: line, tagRange: range, color: .red)
        }
        return Text(.init(line)).foregroundColor(.tmInk)
    }

    private func coloredAnswerText(line: String, tagRange: Range<String.Index>, color: Color) -> Text {
        let label = String(line[..<tagRange.lowerBound])
        let answer = line[tagRange.upperBound...].trimmingCharacters(in: .whitespaces)
        let answerText = Text(.init(answer)).foregroundColor(color).fontWeight(.semibold)
        return Text("\(Text(.init(label)).foregroundColor(.tmInk))\(answerText)")
    }
}
