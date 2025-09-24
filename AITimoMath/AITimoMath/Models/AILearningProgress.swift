import Foundation
import CloudKit

/// Tracks AI-driven learning progress and recommendations for a student
public struct AILearningProgress: Identifiable, Codable, Equatable {
    /// Unique identifier for the learning progress
    public let id: UUID
    
    /// Reference to the user
    public let userId: UUID
    
    /// History of completed lessons with performance metrics
    public var lessonHistory: [LessonProgress]
    
    /// Topics where student needs improvement
    public var weakAreas: [WeakArea]
    
    /// AI-suggested next lessons
    public var recommendedLessons: [UUID]
    
    /// Student's ability level (-3 to +3 scale)
    public var abilityLevel: Float
    
    /// Performance statistics for this student
    public var performanceStats: PerformanceStats
    
    /// Last time AI updated recommendations
    public var lastUpdated: Date
}

// MARK: - Supporting Types
extension AILearningProgress {
    /// Tracks individual lesson performance
    public struct LessonProgress: Codable, Equatable {
        public let lessonId: UUID
        public let subject: Lesson.Subject
        public let completedAt: Date
        public let accuracy: Float
        public let responseTime: TimeInterval
        public var nextDifficulty: Int
        
        public init(
            lessonId: UUID,
            subject: Lesson.Subject,
            completedAt: Date,
            accuracy: Float,
            responseTime: TimeInterval,
            nextDifficulty: Int
        ) {
            self.lessonId = lessonId
            self.subject = subject
            self.completedAt = completedAt
            self.accuracy = accuracy
            self.responseTime = responseTime
            self.nextDifficulty = nextDifficulty
        }
    }
    
    /// Represents an area needing improvement
    public struct WeakArea: Codable, Equatable {
        public let subject: Lesson.Subject
        public var conceptScore: Float
        public var lastPracticed: Date
    }
    
    /// Convenience initialization
    public init(userId: UUID) {
        self.id = UUID()
        self.userId = userId
        self.lessonHistory = []
        self.weakAreas = []
        self.recommendedLessons = []
        self.abilityLevel = 0.0
        self.performanceStats = PerformanceStats()
        self.lastUpdated = Date()
    }
    
    /// Full initialization with all parameters
    public init(
        userId: UUID,
        abilityLevel: Float = 0.0,
        lessonHistory: [LessonProgress] = [],
        weakAreas: [WeakArea] = [],
        recommendedLessons: [UUID] = []
    ) {
        self.id = UUID()
        self.userId = userId
        self.lessonHistory = lessonHistory
        self.weakAreas = weakAreas
        self.recommendedLessons = recommendedLessons
        self.abilityLevel = abilityLevel
        self.performanceStats = PerformanceStats()
        self.lastUpdated = Date()
    }
}

// MARK: - CloudKit Integration
extension AILearningProgress {
    static let recordType = "AILearningProgress"
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        record["id"] = id.uuidString
        record["userId"] = userId.uuidString
        record["lessonHistory"] = try? JSONEncoder().encode(lessonHistory)
        record["weakAreas"] = try? JSONEncoder().encode(weakAreas)
        record["recommendedLessons"] = recommendedLessons.map { $0.uuidString }
        record["abilityLevel"] = abilityLevel
        record["performanceStats"] = try? JSONEncoder().encode(performanceStats)
        record["lastUpdated"] = lastUpdated
        return record
    }
    
    public init?(from record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let userIdString = record["userId"] as? String,
            let userId = UUID(uuidString: userIdString),
            let lessonHistoryData = record["lessonHistory"] as? Data,
            let lessonHistory = try? JSONDecoder().decode([LessonProgress].self, from: lessonHistoryData),
            let weakAreasData = record["weakAreas"] as? Data,
            let weakAreas = try? JSONDecoder().decode([WeakArea].self, from: weakAreasData),
            let recommendedLessonStrings = record["recommendedLessons"] as? [String],
            let statsData = record["performanceStats"] as? Data,
            let performanceStats = try? JSONDecoder().decode(PerformanceStats.self, from: statsData),
            let lastUpdated = record["lastUpdated"] as? Date
        else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.lessonHistory = lessonHistory
        self.weakAreas = weakAreas
        self.recommendedLessons = recommendedLessonStrings.compactMap { UUID(uuidString: $0) }
        self.abilityLevel = record["abilityLevel"] as? Float ?? 0.0
        self.performanceStats = performanceStats
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Progress Analysis & Recommendations
extension AILearningProgress {
    /// Updates learning progress with new lesson completion
    mutating func updateProgress(lesson: Lesson) {
        // Add to lesson history
        let progress = LessonProgress(
            lessonId: lesson.id,
            subject: lesson.subject,
            completedAt: lesson.completedAt ?? Date(),
            accuracy: lesson.accuracy,
            responseTime: lesson.responseTime,
            nextDifficulty: calculateNextDifficulty(lesson)
        )
        lessonHistory.append(progress)
        
        // Update performance stats
        performanceStats.updateWithLesson(lesson)
        
        // Update weak areas
        updateWeakAreas(with: lesson)
        
        // Update ability level
        updateAbilityLevel(with: lesson)
        
        // Generate new recommendations synchronously
        recommendedLessons = generateRecommendations()
        
        lastUpdated = Date()
    }
    
    /// Calculates next lesson difficulty using Adaptive Difficulty Engine
    private func calculateNextDifficulty(_ lesson: Lesson) -> Int {
        let currentDifficulty = lessonHistory.last?.nextDifficulty ?? 1
        
        // Delegate to AdaptiveDifficultyEngine for advanced calculation
        return AdaptiveDifficultyEngine.shared.calculateDifficultyAfterLesson(
            learningProgress: self,
            completedLesson: lesson
        )
    }
    
    /// Updates weak areas based on lesson performance
    private mutating func updateWeakAreas(with lesson: Lesson) {
        // Only update weak areas for completed lessons
        guard lesson.status == .completed,
              let completedAt = lesson.completedAt else {
            return
        }
        
        // Use StudentPerformanceTracker to track lesson completion
        StudentPerformanceTracker.shared.trackLessonCompletion(
            learningProgress: &self,
            lesson: lesson
        )
    }
    
    /// Updates student ability level based on lesson performance
    private mutating func updateAbilityLevel(with lesson: Lesson) {
        // Don't update if not enough data
        guard lessonHistory.count > 0 else {
            abilityLevel = 0.0
            return
        }
        
        // Use CoreML for ability estimation, with fallback to Elo-based calculation
        // Get responses from the lesson
        let responses = lesson.responses.map { response in
            return Lesson.QuestionResponse(
                questionId: response.questionId,
                isCorrect: response.isCorrect,
                responseTime: response.responseTime,
                answeredAt: response.answeredAt,
                selectedAnswer: response.selectedAnswer
            )
        }
        
        // Update ability level using CoreML if available
        let updatedAbility = CoreMLService.shared.estimateStudentAbility(
            currentAbility: abilityLevel,
            responseHistory: responses
        )
        
        // Limit ability level to valid range
        abilityLevel = max(-3.0, min(3.0, updatedAbility))
    }
    
    /// Generates new lesson recommendations
    private func generateRecommendations() -> [UUID] {
        // Add placeholder recommended lessons (one for each subject)
        let subjects = [
            Lesson.Subject.logicalThinking,
            Lesson.Subject.arithmetic,
            Lesson.Subject.numberTheory,
            Lesson.Subject.geometry,
            Lesson.Subject.combinatorics
        ]
        
        // Create a UUID for each subject as a placeholder recommendation
        var newRecommendations: [UUID] = []
        for _ in subjects {
            newRecommendations.append(UUID())
        }
        
        print("Generated \(newRecommendations.count) placeholder recommendations")
        
        return newRecommendations
    }
    
    /// Calculates overall performance score
    private func calculatePerformanceScore(_ lesson: Lesson) -> Float {
        let accuracyWeight: Float = 0.7
        let speedWeight: Float = 0.3
        
        let normalizedSpeed = min(1.0, max(0.0, 1.0 - Float(lesson.responseTime / 60.0)))
        return (lesson.accuracy * accuracyWeight) + (normalizedSpeed * speedWeight)
    }
    
    /// Gets the student's ability level as a descriptive string
    public var abilityLevelDescription: String {
        switch abilityLevel {
        case ..<(-2.0):
            return "Beginner"
        case (-2.0)..<(-1.0):
            return "Developing"
        case (-1.0)...(1.0):
            return "Intermediate"
        case (1.0)...(2.0):
            return "Advanced"
        default:
            return "Expert"
        }
    }
    
    /// Gets the most challenging subjects for this student
    public var challengingSubjects: [Lesson.Subject] {
        // Sort weak areas by concept score (ascending)
        return weakAreas.sorted { $0.conceptScore < $1.conceptScore }.map { $0.subject }
    }
    
    /// Gets the strongest subjects for this student
    public var strongSubjects: [Lesson.Subject] {
        // All subjects
        let allSubjects = [
            Lesson.Subject.logicalThinking,
            Lesson.Subject.arithmetic,
            Lesson.Subject.numberTheory,
            Lesson.Subject.geometry,
            Lesson.Subject.combinatorics
        ]
        
        // Weak subjects
        let weakSubjects = Set(weakAreas.map { $0.subject })
        
        // Return subjects not in weak areas
        return allSubjects.filter { !weakSubjects.contains($0) }
    }
}

/// Overall performance statistics for a student
public struct PerformanceStats: Codable, Equatable {
    /// Overall accuracy across all subjects
    public var overallAccuracy: Float
    
    /// Average response time in seconds
    public var averageResponseTime: TimeInterval
    
    /// Accuracy by subject
    public var subjectAccuracy: [Lesson.Subject: Float]
    
    /// Improvement trend (-1.0 to 1.0, positive means improving)
    public var improvementTrend: Float
    
    /// Total lessons completed
    public var totalLessonsCompleted: Int
    
    /// Initialize with default values
    public init() {
        self.overallAccuracy = 0.0
        self.averageResponseTime = 0.0
        self.subjectAccuracy = [:]
        self.improvementTrend = 0.0
        self.totalLessonsCompleted = 0
    }
    
    /// Update statistics with a completed lesson
    mutating func updateWithLesson(_ lesson: Lesson) {
        // Update overall accuracy
        let oldWeight = Float(totalLessonsCompleted)
        let newWeight = Float(totalLessonsCompleted + 1)
        overallAccuracy = ((overallAccuracy * oldWeight) + lesson.accuracy) / newWeight
        
        // Update average response time
        averageResponseTime = ((averageResponseTime * Double(oldWeight)) + lesson.responseTime) / Double(newWeight)
        
        // Update subject accuracy
        let oldSubjectCount = Float(subjectAccuracy[lesson.subject] != nil ? 1 : 0)
        let oldSubjectAccuracy = subjectAccuracy[lesson.subject] ?? 0.0
        subjectAccuracy[lesson.subject] = ((oldSubjectAccuracy * oldSubjectCount) + lesson.accuracy) / (oldSubjectCount + 1.0)
        
        // Simple trend: compare with overall accuracy
        if lesson.accuracy > overallAccuracy {
            improvementTrend = min(1.0, improvementTrend + 0.1)
        } else if lesson.accuracy < overallAccuracy {
            improvementTrend = max(-1.0, improvementTrend - 0.1)
        }
        
        // Increment total lessons
        totalLessonsCompleted += 1
    }
} 