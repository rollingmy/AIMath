//
//  AITimoMathApp.swift
//  AITimoMath
//
//  Created by My Rolling on 10/3/25.
//

import SwiftUI
import CloudKit
import CoreData
import Combine

@main
struct AITimoMathApp: App {
    /// Shared persistence controller for data management
    let persistenceController = PersistenceController.shared
    
    // App state
    @State private var isOnboardingComplete = false
    @StateObject private var userViewModel: UserViewModel
    
    // Initialize with default user
    init() {
        let defaultUser = User(
            name: "Guest",
            avatar: "avatar-1",
            gradeLevel: 1
        )
        self._userViewModel = StateObject(wrappedValue: UserViewModel(user: defaultUser))
    }
    
    var body: some Scene {
        WindowGroup {
            if isOnboardingComplete {
                MainContentView(userViewModel: userViewModel)
                    .environment(\.managedObjectContext, persistenceController.viewContext)
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .environment(\.managedObjectContext, persistenceController.viewContext)
            }
        }
    }
}

/// Main content view that houses the app's tab navigation after onboarding
struct MainContentView: View {
    @ObservedObject var userViewModel: UserViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home dashboard
            NavigationView {
                HomeView(userViewModel: userViewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Practice/Questions tab
            NavigationView {
                QuestionExampleView(
                    userViewModel: userViewModel,
                    onUserUpdate: { updatedUser in
                        // This would be replaced with proper state management in a real app
                        self.userViewModel.user = updatedUser
                    }
                )
            }
            .tabItem {
                Label("Practice", systemImage: "questionmark.circle.fill")
            }
            .tag(1)
            
            // Performance analytics
            NavigationView {
                PerformanceView(userViewModel: userViewModel)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            // Settings
            NavigationView {
                SettingsView(userViewModel: userViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
            
            #if DEBUG
            // Debug/testing menu (only in debug builds)
            TestMenuView()
                .tabItem {
                    Label("Test Tools", systemImage: "hammer.fill")
                }
                .tag(4)
            #endif
        }
    }
}
