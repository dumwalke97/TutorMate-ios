import SwiftUI
import FirebaseCore

@main
struct TutorMateApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}