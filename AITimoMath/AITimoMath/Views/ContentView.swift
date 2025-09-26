import SwiftUI

struct ContentView: View {
    @AppStorage("isOnboarded") private var isOnboarded = false
    @AppStorage("darkMode") private var darkMode = false
    @State private var user: User = User(
        name: "Test Student",
        avatar: "avatar-boy-1",
        gradeLevel: 5
    )
    private let persistence = PersistenceController.shared
    
    var body: some View {
        if !isOnboarded {
            OnboardingView(isOnboarded: $isOnboarded, user: $user)
                .preferredColorScheme(darkMode ? .dark : .light)
        } else {
            TabView {
                NavigationView {
                    DashboardView(user: user)
                }
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                
                NavigationView {
                    PerformanceView(user: user)
                }
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                
                NavigationView {
                    MistakesReviewView(user: user)
                }
                .tabItem {
                    Label("Review", systemImage: "arrow.clockwise")
                }
                
                NavigationView {
                    SettingsView(user: user)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                
                #if DEBUG
                NavigationView {
                    TestMenuView()
                }
                .tabItem {
                    Label("Test Tools", systemImage: "hammer")
                }
                #endif
            }
            .accentColor(.blue)
            .preferredColorScheme(darkMode ? .dark : .light)
            .onAppear {
                loadUserFromPersistence()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Refresh user data when app becomes active
                loadUserFromPersistence()
            }
        }
    }
    
    /// Load user data from Core Data persistence
    private func loadUserFromPersistence() {
        do {
            // First, try to fetch any existing user (there should only be one)
            let allUsers = try persistence.fetchAllUsers()
            
            if let stored = allUsers.first {
                // Replace the entire user object with the stored one
                // This ensures we use the correct UUID and all properties
                self.user = stored
                print("User data loaded from persistence: \(stored.name)")
            } else {
                // Save default user if not found
                try persistence.saveUser(user)
                print("Default user saved to persistence")
            }
        } catch {
            print("Error loading user from persistence: \(error)")
            // If there's an error, try to save the default user
            do {
                try persistence.saveUser(user)
                print("Default user saved after error")
            } catch {
                print("Failed to save default user: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 