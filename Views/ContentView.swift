import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = TutorMateViewModel()
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation Bar
                    CustomNavigationBar(viewModel: viewModel)
                    
                    // Main Content
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
                        .padding()
                    }
                }
            }
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
