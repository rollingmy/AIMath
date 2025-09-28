import Foundation
import Combine

/// User model representing a student in the TIMO Math Lessons app
/// Conforms to necessary protocols for Core Data persistence and secure data handling
public class User: Identifiable, Codable, Equatable, ObservableObject {
    /// Unique identifier for the user
    public let id: UUID
    
    /// Student's display name (encrypted when stored)
    @Published public var name: String
    
    /// Avatar image identifier
    @Published public var avatar: String
    
    /// Student's grade level (1-6 for primary school)
    @Published public var gradeLevel: Int
    
    /// Daily learning goal (number of questions per session)
    @Published public var learningGoal: Int
    
    /// Current difficulty level setting
    @Published public var difficultyLevel: DifficultyLevel
    
    /// Array of completed lesson IDs
    @Published public var completedLessons: [UUID]
    
    /// Timestamp of last activity
    @Published public var lastActiveAt: Date
    
    /// Creation timestamp
    public let createdAt: Date
    
    // Additional properties referenced in the code
    @Published public var dailyGoal: Int
    @Published public var dailyCompletedQuestions: Int
    
    // Auto-save mechanism
    private var saveCancellable: AnyCancellable?
    private let saveQueue = DispatchQueue(label: "user.save", qos: .utility)
    
    // Define CodingKeys to handle @Published properties
    private enum CodingKeys: String, CodingKey {
        case id, name, avatar, gradeLevel, learningGoal, difficultyLevel, completedLessons, lastActiveAt, createdAt, dailyGoal, dailyCompletedQuestions
    }
    
    // Required for Equatable
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.avatar == rhs.avatar &&
               lhs.gradeLevel == rhs.gradeLevel &&
               lhs.learningGoal == rhs.learningGoal &&
               lhs.difficultyLevel == rhs.difficultyLevel &&
               lhs.completedLessons == rhs.completedLessons &&
               lhs.lastActiveAt == rhs.lastActiveAt &&
               lhs.createdAt == rhs.createdAt &&
               lhs.dailyGoal == rhs.dailyGoal &&
               lhs.dailyCompletedQuestions == rhs.dailyCompletedQuestions
    }
    
    // Custom encoder to handle @Published properties
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(gradeLevel, forKey: .gradeLevel)
        try container.encode(learningGoal, forKey: .learningGoal)
        try container.encode(difficultyLevel, forKey: .difficultyLevel)
        try container.encode(completedLessons, forKey: .completedLessons)
        try container.encode(lastActiveAt, forKey: .lastActiveAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(dailyGoal, forKey: .dailyGoal)
        try container.encode(dailyCompletedQuestions, forKey: .dailyCompletedQuestions)
    }
    
    // Custom initializer for Codable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decode(String.self, forKey: .avatar)
        gradeLevel = try container.decode(Int.self, forKey: .gradeLevel)
        learningGoal = try container.decode(Int.self, forKey: .learningGoal)
        difficultyLevel = try container.decode(DifficultyLevel.self, forKey: .difficultyLevel)
        completedLessons = try container.decode([UUID].self, forKey: .completedLessons)
        lastActiveAt = try container.decode(Date.self, forKey: .lastActiveAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        dailyGoal = try container.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 10
        dailyCompletedQuestions = try container.decodeIfPresent(Int.self, forKey: .dailyCompletedQuestions) ?? 0
    }
    
    /// Designated initializer with all properties
    public init(
        id: UUID,
        name: String,
        avatar: String,
        gradeLevel: Int,
        learningGoal: Int,
        difficultyLevel: DifficultyLevel,
        completedLessons: [UUID],
        lastActiveAt: Date,
        createdAt: Date,
        dailyGoal: Int,
        dailyCompletedQuestions: Int
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.gradeLevel = gradeLevel
        self.learningGoal = learningGoal
        self.difficultyLevel = difficultyLevel
        self.completedLessons = completedLessons
        self.lastActiveAt = lastActiveAt
        self.createdAt = createdAt
        self.dailyGoal = dailyGoal
        self.dailyCompletedQuestions = dailyCompletedQuestions
        
        // Setup auto-save mechanism
        setupAutoSave()
    }
}

// MARK: - Supporting Types
extension User {
    /// Difficulty levels available in the app
    public enum DifficultyLevel: String, Codable {
        case beginner
        case adaptive
        case advanced
        
        /// Get the appropriate difficulty range for this level
        public var difficultyRange: [Int] {
            switch self {
            case .beginner:
                return [1, 2] // Easy and Medium
            case .adaptive:
                return [1, 2, 3, 4] // All difficulties
            case .advanced:
                return [3, 4] // Hard and Olympiad
            }
        }
        
        /// Get display name for the difficulty level
        public var displayName: String {
            switch self {
            case .beginner:
                return "Beginner"
            case .adaptive:
                return "Adaptive"
            case .advanced:
                return "Advanced"
            }
        }
    }
    
    /// Convenience initialization with default values
    public convenience init(
        name: String,
        avatar: String,
        gradeLevel: Int,
        dailyGoal: Int = 10,
        dailyCompletedQuestions: Int = 0
    ) {
        self.init(
            id: UUID(),
            name: name,
            avatar: avatar,
            gradeLevel: gradeLevel,
            learningGoal: 10,
            difficultyLevel: .adaptive,
            completedLessons: [],
            lastActiveAt: Date(),
            createdAt: Date(),
            dailyGoal: dailyGoal,
            dailyCompletedQuestions: dailyCompletedQuestions
        )
    }
}

// MARK: - Auto-Save Functionality
extension User {
    /// Setup automatic saving to Core Data when user properties change
    private func setupAutoSave() {
        // Listen to changes in key properties and auto-save
        saveCancellable = Publishers.Merge4(
            $name.map { _ in () },
            $avatar.map { _ in () },
            $gradeLevel.map { _ in () },
            $dailyGoal.map { _ in () }
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.saveToCoreData()
        }
    }
    
    /// Save user data to Core Data
    private func saveToCoreData() {
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try PersistenceController.shared.saveUser(self)
                print("User auto-saved successfully: \(self.name) (ID: \(self.id))")
            } catch {
                print("Error auto-saving user: \(error)")
            }
        }
    }
    
    /// Manually trigger a save (useful for immediate persistence)
    public func saveNow() {
        saveToCoreData()
    }
}

// MARK: - Core Data Integration
// Note: Core Data integration is handled in CoreDataExtensions.swift

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
    func trackActivity() {
        self.lastActiveAt = Date()
    }
    
    /// Add completed lesson
    func addCompletedLesson(_ lessonId: UUID) {
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
    func updateDifficultyLevel(_ newLevel: DifficultyLevel) {
        self.difficultyLevel = newLevel
        trackActivity()
    }
    
    /// Update learning goal
    func updateLearningGoal(_ newGoal: Int) throws {
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
