import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct TutorMateApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            await FirebaseManager.shared.ensureSignedIn()
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeOut(duration: 0.45)) {
                showSplash = false
            }
        }
    }
}

struct SplashView: View {
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Color.tmCanvas
                .ignoresSafeArea()

            Image("TutorMateLogoTransparent")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.94)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    SplashView()
}
