import Foundation
import SwiftUI

/// Extensions for Int type
extension Int {
    /// Get difficulty name from difficulty level
    var difficultyName: String {
        switch self {
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
} 