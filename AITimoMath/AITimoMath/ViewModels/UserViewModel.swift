import Foundation
import Combine

/// View model for User data that provides observable behavior for SwiftUI views
class UserViewModel: ObservableObject {
    /// The wrapped user model
    @Published internal var user: User
    
    /// Initialization with a User model
    init(user: User) {
        self.user = user
    }
    
    /// User's ID (passthrough to wrapped user)
    var id: UUID {
        user.id
    }
    
    /// User's name (passthrough to wrapped user)
    var name: String {
        user.name
    }
    
    /// User's avatar (passthrough to wrapped user)
    var avatar: String {
        user.avatar
    }
    
    /// User's grade level (passthrough to wrapped user)
    var gradeLevel: Int {
        user.gradeLevel
    }
    
    /// User's learning goal (passthrough to wrapped user)
    var learningGoal: Int {
        user.learningGoal
    }
    
    /// User's difficulty level (passthrough to wrapped user)
    var difficultyLevel: User.DifficultyLevel {
        user.difficultyLevel
    }
    
    /// User's completed lessons (passthrough to wrapped user)
    var completedLessons: [UUID] {
        user.completedLessons
    }
    
    /// Track user activity
    func trackActivity() {
        var updatedUser = user
        updatedUser.trackActivity()
        user = updatedUser
    }
    
    /// Add completed lesson
    func addCompletedLesson(_ lessonId: UUID) {
        var updatedUser = user
        updatedUser.addCompletedLesson(lessonId)
        user = updatedUser
    }
    
    /// Update user's difficulty level
    func updateDifficultyLevel(_ newLevel: User.DifficultyLevel) {
        var updatedUser = user
        updatedUser.updateDifficultyLevel(newLevel)
        user = updatedUser
    }
    
    /// Update learning goal
    func updateLearningGoal(_ newGoal: Int) throws {
        var updatedUser = user
        try updatedUser.updateLearningGoal(newGoal)
        user = updatedUser
    }
    
    /// User's completion rate
    var completionRate: Float {
        user.completionRate
    }
    
    /// User's progress status
    var progressStatus: User.ProgressStatus {
        user.progressStatus
    }
} 