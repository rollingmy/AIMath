//
//  AITimoMathApp.swift
//  AITimoMath
//
//  Created by My Rolling on 10/3/25.
//

import SwiftUI
import CoreData

@main
struct AITimoMathApp: App {
    /// Shared persistence controller for data management
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView(persistenceController: persistenceController)
        }
    }
}
