import Foundation
import SwiftUI

/// Extensions for Lesson.Subject enum
extension Lesson.Subject {
    /// Get color for subject
    var color: Color {
        switch self {
        case .logicalThinking:
            return .blue
        case .arithmetic:
            return .green
        case .numberTheory:
            return .purple
        case .geometry:
            return .orange
        case .combinatorics:
            return .red
        }
    }
    
    /// Get display name for subject
    var displayName: String {
        switch self {
        case .logicalThinking:
            return "Logical Thinking"
        case .arithmetic:
            return "Arithmetic"
        case .numberTheory:
            return "Number Theory"
        case .geometry:
            return "Geometry"
        case .combinatorics:
            return "Combinatorics"
        }
    }
} 