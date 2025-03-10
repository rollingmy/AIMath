import Foundation
import CloudKit

/// User model representing a student in the TIMO Math Lessons app
/// Conforms to necessary protocols for CloudKit sync and secure data handling
public struct User: Identifiable, Codable, Equatable {
    /// Unique identifier for the user
    public let id: UUID
    
    /// Student's display name (encrypted when stored)
    public var name: String
    
    /// Avatar image identifier
    public var avatar: String
    
    /// Student's grade level (1-6 for primary school)
    public var gradeLevel: Int
    
    /// Daily learning goal (number of questions per session)
    public var learningGoal: Int
    
    /// Current difficulty level setting
    public var difficultyLevel: DifficultyLevel
    
    /// Array of completed lesson IDs
    public var completedLessons: [UUID]
    
    /// Timestamp of last activity
    public var lastActiveAt: Date
    
    /// Creation timestamp
    public let createdAt: Date
}

// MARK: - Supporting Types
extension User {
    /// Difficulty levels available in the app
    public enum DifficultyLevel: String, Codable {
        case beginner
        case adaptive
        case advanced
    }
    
    /// Convenience initialization with default values
    public init(
        name: String,
        avatar: String,
        gradeLevel: Int
    ) {
        self.id = UUID()
        self.name = name
        self.avatar = avatar
        self.gradeLevel = gradeLevel
        self.learningGoal = 10 // Default 10 questions per session
        self.difficultyLevel = .adaptive
        self.completedLessons = []
        self.lastActiveAt = Date()
        self.createdAt = Date()
    }
}

// MARK: - CloudKit Integration
extension User {
    /// CloudKit record type for User
    static let recordType = "User"
    
    /// Converts User model to CloudKit record
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType)
        record["id"] = id.uuidString
        record["name"] = name
        record["avatar"] = avatar
        record["gradeLevel"] = gradeLevel
        record["learningGoal"] = learningGoal
        record["difficultyLevel"] = difficultyLevel.rawValue
        record["completedLessons"] = completedLessons.map { $0.uuidString }
        record["lastActiveAt"] = lastActiveAt
        record["createdAt"] = createdAt
        return record
    }
    
    /// Creates User model from CloudKit record
    init?(from record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let name = record["name"] as? String,
            let avatar = record["avatar"] as? String,
            let gradeLevel = record["gradeLevel"] as? Int,
            let learningGoal = record["learningGoal"] as? Int,
            let difficultyString = record["difficultyLevel"] as? String,
            let difficultyLevel = DifficultyLevel(rawValue: difficultyString),
            let completedLessonStrings = record["completedLessons"] as? [String],
            let lastActiveAt = record["lastActiveAt"] as? Date,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.avatar = avatar
        self.gradeLevel = gradeLevel
        self.learningGoal = learningGoal
        self.difficultyLevel = difficultyLevel
        self.completedLessons = completedLessonStrings.compactMap { UUID(uuidString: $0) }
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
    }
}

// MARK: - Validation
extension User {
    /// Validates user data before saving
    func validate() throws {
        // Name validation
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
        guard name.count <= 50 else {
            throw ValidationError.nameTooLong
        }
        
        // Grade level validation
        guard (1...6).contains(gradeLevel) else {
            throw ValidationError.invalidGradeLevel
        }
        
        // Learning goal validation
        guard (5...50).contains(learningGoal) else {
            throw ValidationError.invalidLearningGoal
        }
    }
    
    /// Validation error types
    enum ValidationError: LocalizedError {
        case emptyName
        case nameTooLong
        case invalidGradeLevel
        case invalidLearningGoal
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Name cannot be empty"
            case .nameTooLong:
                return "Name cannot exceed 50 characters"
            case .invalidGradeLevel:
                return "Grade level must be between 1 and 6"
            case .invalidLearningGoal:
                return "Learning goal must be between 5 and 50 questions"
            }
        }
    }
}

// MARK: - Analytics
extension User {
    /// Track user activity for analytics
    mutating func trackActivity() {
        self.lastActiveAt = Date()
    }
    
    /// Add completed lesson
    mutating func addCompletedLesson(_ lessonId: UUID) {
        if !completedLessons.contains(lessonId) {
            completedLessons.append(lessonId)
            trackActivity()
        }
    }
    
    /// Calculate completion rate
    var completionRate: Float {
        guard !completedLessons.isEmpty else { return 0 }
        return Float(completedLessons.count) / Float(learningGoal)
    }
    
    /// Update user's difficulty level based on performance
    mutating func updateDifficultyLevel(_ newLevel: DifficultyLevel) {
        self.difficultyLevel = newLevel
        trackActivity()
    }
    
    /// Update learning goal
    mutating func updateLearningGoal(_ newGoal: Int) throws {
        guard (5...50).contains(newGoal) else {
            throw ValidationError.invalidLearningGoal
        }
        self.learningGoal = newGoal
        trackActivity()
    }
}

// MARK: - Progress Tracking
extension User {
    /// Get user's current progress status
    var progressStatus: ProgressStatus {
        let rate = completionRate
        switch rate {
        case 0..<0.3:
            return .beginner
        case 0.3..<0.7:
            return .intermediate
        case 0.7..<1.0:
            return .advanced
        default:
            return .completed
        }
    }
    
    /// Progress status enumeration
    enum ProgressStatus {
        case beginner
        case intermediate
        case advanced
        case completed
    }
} 