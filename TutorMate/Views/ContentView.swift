import SwiftUI
import PhotosUI

enum AppTab: Hashable {
    case home
    case folders
}

struct ContentView: View {
    @StateObject private var viewModel = TutorMateViewModel()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tmCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
                    .padding(.bottom, 4)

                ScrollView {
                    Group {
                        switch selectedTab {
                        case .home:
                            homeContent
                        case .folders:
                            foldersContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                }
                .scrollIndicators(.hidden)
            }

            floatingTabBar
                .padding(.bottom, 4)
        }
        .sheet(isPresented: $viewModel.showLoginModal) {
            LoginView(viewModel: viewModel)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: viewModel.currentState) { newState in
            switch newState {
            case .folders, .folderContents:
                if selectedTab != .folders { selectedTab = .folders }
            default:
                if selectedTab != .home { selectedTab = .home }
            }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        VStack(spacing: 20) {
            switch viewModel.currentState {
            case .loading:
                LoadingView(viewModel: viewModel)
            case .quiz:
                QuizView(viewModel: viewModel)
            case .results:
                ResultsView(viewModel: viewModel)
            case .review:
                ReviewView(viewModel: viewModel)
            case .assignmentResults:
                AssignmentResultsView(viewModel: viewModel)
            default:
                UploadView(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private var foldersContent: some View {
        VStack(spacing: 20) {
            switch viewModel.currentState {
            case .folderContents:
                FolderContentsView(viewModel: viewModel)
            default:
                FoldersListView(viewModel: viewModel)
            }
        }
    }

    private var floatingTabBar: some View {
        HStack(spacing: 4) {
            tabPill(.home, icon: "house.fill", label: "Home")
            tabPill(.folders, icon: "folder.fill", label: "Folders")
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.tmInk.opacity(0.12), radius: 14, x: 0, y: 6)
    }

    private func tabPill(_ tab: AppTab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectTab(tab)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .tmNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? Color.tmNavy : Color.clear)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func selectTab(_ tab: AppTab) {
        selectedTab = tab
        switch tab {
        case .home:
            if viewModel.currentState == .folders || viewModel.currentState == .folderContents {
                viewModel.currentState = .upload
            }
        case .folders:
            if viewModel.currentState != .folders && viewModel.currentState != .folderContents {
                viewModel.currentState = .folders
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
