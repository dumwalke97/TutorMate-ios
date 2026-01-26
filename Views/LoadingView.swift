struct LoadingView: View {
    @ObservedObject var viewModel: TutorMateViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
            
            Text("\(Int(viewModel.progress * 100))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text(viewModel.loadingText)
                .font(.system(size: 20, weight: .semibold))
                .padding(.top)
            
            Text("Please wait a moment.")
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
