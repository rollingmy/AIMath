//
//  AITimoMathApp.swift
//  AITimoMath
//
//  Created by My Rolling on 10/3/25.
//

import SwiftUI
import CloudKit
import CoreData

@main
struct AITimoMathApp: App {
    /// Shared persistence controller for data management
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}

struct ContentView: View {
    // Create a view model for the user
    @State private var userViewModel: UserViewModel
    
    // Initializer to create the UserViewModel
    init() {
        let user = User(
            name: "Test Student",
            avatar: "avatar-1",
            gradeLevel: 5
        )
        self._userViewModel = State(initialValue: UserViewModel(user: user))
    }
    
    var body: some View {
        TabView {
            // Main Dashboard Screen
            NavigationView {
                DashboardView(userViewModel: userViewModel)
            }
            .tabItem {
                Label("Dashboard", systemImage: "house")
            }
            
            // AIRecommendations Tab
            NavigationView {
                AIRecommendationView(userId: userViewModel.id)
            }
            .tabItem {
                Label("Recommendations", systemImage: "lightbulb")
            }
            
            // Progress Tab
            NavigationView {
                ProgressReportView(userViewModel: userViewModel)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar")
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
