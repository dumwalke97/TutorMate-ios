import SwiftUI

struct LoadingView: View {
    @ObservedObject var viewModel: TutorMateViewModel

    var body: some View {
        VStack(spacing: 14) {
            Text(viewModel.loadingText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.tmNavy)

            Text("Please wait a moment.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(.tmNavy)
                .padding(.top, 6)

            Text("\(Int(viewModel.progress * 100))%")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.tmCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.tmNavy.opacity(0.05), radius: 14, x: 0, y: 6)
    }
}
