import SwiftUI
import FirebaseCore // Make sure this is imported

@main
struct TutorMateApp: App {
    
    // Add this init() block:
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView() // or whatever your starting view is
        }
    }
}
