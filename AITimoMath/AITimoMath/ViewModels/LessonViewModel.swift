import Foundation
import SwiftUI

/// View model for Lesson that provides additional utility functions for the UI
class LessonViewModel: ObservableObject {
    /// The wrapped lesson model
    @Published var lesson: Lesson
    
    /// Initialize with a lesson
    init(lesson: Lesson) {
        self.lesson = lesson
    }
    
    /// Get a user-friendly name for difficulty level
    var difficultyName: String {
        switch lesson.difficulty {
        case 1:
            return "Easy"
        case 2:
            return "Medium"
        case 3:
            return "Hard"
        case 4:
            return "Olympiad"
        default:
            return "Unknown"
        }
    }
    
    /// Get a color representing the subject
    var subjectColor: Color {
        switch lesson.subject {
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
    
    /// Get a system image name for the subject
    var subjectIconName: String {
        switch lesson.subject {
        case .logicalThinking:
            return "brain"
        case .arithmetic:
            return "plus.forwardslash.minus"
        case .numberTheory:
            return "number"
        case .geometry:
            return "triangle"
        case .combinatorics:
            return "square.grid.2x2"
        }
    }
    
    /// Get a display name for the subject
    var subjectDisplayName: String {
        switch lesson.subject {
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