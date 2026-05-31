import SwiftUI

/// The main entry point for the NetProof application.
/// This structure initializes the application lifecycle and sets the root view.
@main
struct NetProofApp: App {
    
    // Note: Credit management logic has been removed to maintain a lean architecture.
    // The app now initializes in a clean state, focusing on UI and ViewModel injection.
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
