import SwiftUI

struct ContentView: View {
    @AppStorage("isOnboarded") private var isOnboarded = false
    @State private var user = User(
        name: "Test Student",
        avatar: "avatar-1",
        gradeLevel: 5
    )
    
    var body: some View {
        if !isOnboarded {
            OnboardingView(isOnboarded: $isOnboarded, user: $user)
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 