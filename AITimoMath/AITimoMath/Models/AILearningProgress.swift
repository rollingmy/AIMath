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
    
    /// Last time AI updated recommendations
    public var lastUpdated: Date
}

// MARK: - Supporting Types
extension AILearningProgress {
    /// Tracks individual lesson performance
    public struct LessonProgress: Codable, Equatable {
        public let lessonId: UUID
        public let subject: Lesson.Subject
        public let accuracy: Float
        public let responseTime: TimeInterval
        public var nextDifficulty: Int
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
        self.lastUpdated = Date()
    }
}

// MARK: - CloudKit Integration
extension AILearningProgress {
    static let recordType = "AILearningProgress"
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: AILearningProgress.recordType)
        record["userId"] = userId.uuidString
        
        // Convert lesson history to dictionary for storage
        let historyData = try? JSONEncoder().encode(lessonHistory)
        record["lessonHistory"] = historyData
        
        // Convert weak areas to dictionary for storage
        let weakAreasData = try? JSONEncoder().encode(weakAreas)
        record["weakAreas"] = weakAreasData
        
        record["recommendedLessons"] = recommendedLessons.map { $0.uuidString }
        record["lastUpdated"] = lastUpdated
        return record
    }
    
    init?(from record: CKRecord) {
        guard
            let userIdString = record["userId"] as? String,
            let userId = UUID(uuidString: userIdString),
            let historyData = record["lessonHistory"] as? Data,
            let weakAreasData = record["weakAreas"] as? Data,
            let recommendedStrings = record["recommendedLessons"] as? [String],
            let lastUpdated = record["lastUpdated"] as? Date,
            let lessonHistory = try? JSONDecoder().decode([LessonProgress].self, from: historyData),
            let weakAreas = try? JSONDecoder().decode([WeakArea].self, from: weakAreasData)
        else {
            return nil
        }
        
        self.id = UUID()
        self.userId = userId
        self.lessonHistory = lessonHistory
        self.weakAreas = weakAreas
        self.recommendedLessons = recommendedStrings.compactMap { UUID(uuidString: $0) }
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
            accuracy: lesson.accuracy,
            responseTime: lesson.responseTime,
            nextDifficulty: calculateNextDifficulty(lesson)
        )
        lessonHistory.append(progress)
        
        // Update weak areas
        updateWeakAreas(with: lesson)
        
        // Generate new recommendations
        updateRecommendations()
        
        lastUpdated = Date()
    }
    
    /// Calculates next lesson difficulty using Elo Rating & BKT
    private func calculateNextDifficulty(_ lesson: Lesson) -> Int {
        let currentDifficulty = lessonHistory.last?.nextDifficulty ?? 1
        let performanceScore = calculatePerformanceScore(lesson)
        
        // Apply Elo Rating adjustment
        let adjustment = performanceScore > 0.8 ? 1 : (performanceScore < 0.4 ? -1 : 0)
        let newDifficulty = max(1, min(4, currentDifficulty + adjustment))
        
        return newDifficulty
    }
    
    /// Updates weak areas based on lesson performance
    private mutating func updateWeakAreas(with lesson: Lesson) {
        // Only update weak areas for completed lessons
        guard lesson.status == .completed,
              let completedAt = lesson.completedAt else {
            return
        }
        
        if lesson.accuracy < 0.7 {
            if let index = weakAreas.firstIndex(where: { $0.subject == lesson.subject }) {
                weakAreas[index].conceptScore = min(weakAreas[index].conceptScore, lesson.accuracy)
                weakAreas[index].lastPracticed = completedAt
            } else {
                weakAreas.append(WeakArea(
                    subject: lesson.subject,
                    conceptScore: lesson.accuracy,
                    lastPracticed: completedAt
                ))
            }
        }
    }
    
    /// Generates new lesson recommendations
    private mutating func updateRecommendations() {
        // Prioritize weak areas that haven't been practiced recently
        let now = Date()
        let sortedWeakAreas = weakAreas.sorted { area1, area2 in
            // First sort by concept score (ascending)
            if area1.conceptScore != area2.conceptScore {
                return area1.conceptScore < area2.conceptScore
            }
            // Then by last practice date (oldest first)
            return area1.lastPracticed < area2.lastPracticed
        }
        
        // Get top 2 subjects that need most practice
        let weakSubjects = sortedWeakAreas.prefix(2).map { $0.subject }
        
        // TODO: Implement actual lesson recommendation logic
        // This would involve fetching available lessons and
        // selecting based on weak areas and current difficulty
    }
    
    /// Calculates overall performance score
    private func calculatePerformanceScore(_ lesson: Lesson) -> Float {
        let accuracyWeight: Float = 0.7
        let speedWeight: Float = 0.3
        
        let normalizedSpeed = min(1.0, max(0.0, 1.0 - Float(lesson.responseTime / 60.0)))
        return (lesson.accuracy * accuracyWeight) + (normalizedSpeed * speedWeight)
    }
} 