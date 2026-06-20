import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = TutorMateViewModel()
    @StateObject private var firebaseManager = FirebaseManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tmCanvas
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    CustomNavigationBar(viewModel: viewModel)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 14)

                    ScrollView {
                        VStack(spacing: 20) {
                            switch viewModel.currentState {
                            case .upload:
                                UploadView(viewModel: viewModel)
                            case .loading:
                                LoadingView(viewModel: viewModel)
                            case .quiz:
                                QuizView(viewModel: viewModel)
                            case .results:
                                ResultsView(viewModel: viewModel)
                            case .review:
                                ReviewView(viewModel: viewModel)
                            case .folders:
                                FoldersListView(viewModel: viewModel)
                            case .folderContents:
                                FolderContentsView(viewModel: viewModel)
                            case .assignmentResults:
                                AssignmentResultsView(viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.showLoginModal) {
                LoginView(viewModel: viewModel)
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

extension Color {
    static let tmNavy = Color(red: 0.11, green: 0.17, blue: 0.38)
    static let tmNavySoft = Color(red: 0.18, green: 0.24, blue: 0.46)
    static let tmCanvas = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let tmCard = Color.white
    static let tmFieldFill = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let tmInk = Color(red: 0.07, green: 0.10, blue: 0.20)
}

#Preview {
    ContentView()
}
