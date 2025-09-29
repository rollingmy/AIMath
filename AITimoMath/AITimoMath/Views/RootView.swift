import SwiftUI

/// Root view that serves as the main app entry point
struct RootView: View {
    // Persistence controller for data management
    let persistenceController: PersistenceController
    
    // Use feature flag to switch between implementations
    @AppStorage("useNewUI") private var useNewUI = true
    
    var body: some View {
        if useNewUI {
            // Use our new UI implementation
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        } else {
            // Use the original UI implementation
            LegacyContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}

/// Original content view implementation for backward compatibility
struct LegacyContentView: View {
    // Create a shared user for testing
    @State private var currentUser = User(
        name: "Test Student",
        avatar: "avatar-1",
        gradeLevel: 5
    )
    
    var body: some View {
        TabView {
            QuestionExampleView(user: currentUser, onUserUpdate: { updatedUser in
                self.currentUser = updatedUser
            })
                .tabItem {
                    Label("Questions", systemImage: "questionmark.circle")
                }
            
            AIRecommendationView(user: currentUser)
                .tabItem {
                    Label("Recommendations", systemImage: "lightbulb")
                }
            
            #if DEBUG
            TestMenuView()
                .tabItem {
                    Label("Test Tools", systemImage: "hammer")
                }
            #endif
        }
    }
} 