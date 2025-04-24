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
            
            AIRecommendationView(userId: currentUser.id)
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
