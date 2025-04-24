import Foundation

/// Tracks and analyzes student performance data for AI-powered learning
public class StudentPerformanceTracker {
    /// Singleton instance for app-wide use
    public static let shared = StudentPerformanceTracker()
    
    /// Initialize the performance tracker
    private init() {}
    
    // MARK: - Type Aliases
    private typealias LearningProgress = AITimoMath.AILearningProgress
    
    /// Track a completed lesson to update student performance metrics
    /// - Parameters:
    ///   - learningProgress: The student's learning progress
    ///   - lesson: The lesson that was completed
    /// - Returns: Updated learning progress with weak areas and recommendations
    public func trackLessonCompletion(
        learningProgress: inout AITimoMath.AILearningProgress,
        lesson: Lesson
    ) {
        // Ensure the lesson is completed
        guard lesson.status == .completed,
              let completedAt = lesson.completedAt else {
            return
        }
        
        // Update weak areas based on performance
        updateWeakAreas(in: &learningProgress, with: lesson, completedAt: completedAt)
        
        // Generate key performance insights
        let insights = generatePerformanceInsights(from: lesson)
        storePerformanceInsights(insights, for: learningProgress.userId)
        
        // Update the timestamp
        learningProgress.lastUpdated = Date()
    }
    
    /// Analyze student performance to identify weak areas
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - responseHistory: The student's response history
    /// - Returns: Array of identified weak areas
    public func identifyWeakAreas(
        userId: UUID,
        responseHistory: [Lesson.QuestionResponse]
    ) async throws -> [AITimoMath.AILearningProgress.WeakArea] {
        // Group responses by subject
        let subjectResponses = await groupResponsesBySubject(userId: userId, responses: responseHistory)
        
        var weakAreas: [AITimoMath.AILearningProgress.WeakArea] = []
        let now = Date()
        
        // Identify weak areas for each subject
        for (subject, responses) in subjectResponses {
            // Calculate accuracy for this subject
            let totalResponses = responses.count
            let correctResponses = responses.filter { $0.isCorrect }.count
            let accuracy = Float(correctResponses) / Float(totalResponses)
            
            // Get the most recent response time for this subject
            let mostRecentResponse = responses.max(by: { $0.answeredAt < $1.answeredAt })
            let lastPracticed = mostRecentResponse?.answeredAt ?? now
            
            // If accuracy is below threshold, mark as a weak area
            if accuracy < 0.7 {
                weakAreas.append(AITimoMath.AILearningProgress.WeakArea(
                    subject: subject,
                    conceptScore: accuracy,
                    lastPracticed: lastPracticed
                ))
            }
        }
        
        return weakAreas
    }
    
    /// Generate learning path recommendations based on performance
    /// - Parameter userId: The user's ID
    /// - Returns: Array of recommended lesson types
    public func generateLearningPathRecommendations(
        userId: UUID
    ) async throws -> [LearningPathRecommendation] {
        // In a real implementation, this would analyze complete learning history
        // For now, we'll return a simplified set of recommendations
        
        // Try to get learning progress
        if let learningProgress = try? await AILearningService.shared.getLearningProgress(userId: userId) {
            var recommendations: [LearningPathRecommendation] = []
            
            // Recommend based on weak areas
            for weakArea in learningProgress.weakAreas {
                recommendations.append(LearningPathRecommendation(
                    subject: weakArea.subject,
                    recommendationType: .reinforcement,
                    difficulty: max(1, min(4, calculateDifficultyForWeakArea(weakArea)))
                ))
            }
            
            // If we have at least 3 completed lessons, check for progress and suggest advancement
            if learningProgress.lessonHistory.count >= 3 {
                let recentProgress = analyzeRecentProgressTrend(learningProgress)
                
                // For subjects with positive trends, recommend advancement
                for subject in Lesson.Subject.allCases where !recommendations.contains(where: { $0.subject == subject }) {
                    if let trend = recentProgress[subject], trend > 0.1 {
                        // Positive trend, recommend advancement
                        let currentDifficulty = getCurrentDifficultyForSubject(subject, in: learningProgress)
                        recommendations.append(LearningPathRecommendation(
                            subject: subject,
                            recommendationType: .advancement,
                            difficulty: min(4, currentDifficulty + 1)
                        ))
                    }
                }
            }
            
            // Fill remaining subjects with exploration recommendations
            for subject in Lesson.Subject.allCases where !recommendations.contains(where: { $0.subject == subject }) {
                let currentDifficulty = getCurrentDifficultyForSubject(subject, in: learningProgress)
                recommendations.append(LearningPathRecommendation(
                    subject: subject,
                    recommendationType: .exploration,
                    difficulty: currentDifficulty
                ))
            }
            
            return recommendations
        }
        
        // If no progress data, return basic recommendations for all subjects
        return Lesson.Subject.allCases.map { subject in
            LearningPathRecommendation(
                subject: subject,
                recommendationType: .exploration,
                difficulty: 1 // Start with easiest level
            )
        }
    }
    
    /// Calculate learning speed for a student
    /// - Parameter userId: The user's ID
    /// - Returns: Learning speed metrics
    public func calculateLearningSpeed(userId: UUID) async throws -> LearningSpeedMetrics {
        guard let learningProgress = try? await AILearningService.shared.getLearningProgress(userId: userId),
              !learningProgress.lessonHistory.isEmpty else {
            return LearningSpeedMetrics()
        }
        
        // Calculate average response time
        let totalResponseTime = learningProgress.lessonHistory.reduce(0.0) { $0 + $1.responseTime }
        let averageResponseTime = totalResponseTime / Double(learningProgress.lessonHistory.count)
        
        // Calculate response time trend
        let responseTimeTrend = calculateResponseTimeTrend(learningProgress.lessonHistory)
        
        // Calculate mastery speed (approximation based on difficulty progression)
        var masterySpeed: Float = 1.0
        if learningProgress.lessonHistory.count >= 3 {
            // Calculate how quickly difficulty is increasing
            let difficultyProgression = calculateDifficultyProgression(learningProgress.lessonHistory)
            masterySpeed = max(0.1, min(3.0, difficultyProgression * 2.0))
        }
        
        return LearningSpeedMetrics(
            averageResponseTime: averageResponseTime,
            responseTimeTrend: responseTimeTrend,
            masterySpeed: masterySpeed
        )
    }
    
    // MARK: - Helper Methods
    
    /// Update weak areas based on lesson performance
    private func updateWeakAreas(
        in learningProgress: inout AITimoMath.AILearningProgress,
        with lesson: Lesson,
        completedAt: Date
    ) {
        // Check if performance is below threshold to be considered a weak area
        if lesson.accuracy < 0.7 {
            // Check if this subject is already a weak area
            if let index = learningProgress.weakAreas.firstIndex(where: { $0.subject == lesson.subject }) {
                // Update existing weak area
                if lesson.accuracy < learningProgress.weakAreas[index].conceptScore {
                    learningProgress.weakAreas[index].conceptScore = lesson.accuracy
                }
                learningProgress.weakAreas[index].lastPracticed = completedAt
            } else {
                // Add new weak area
                learningProgress.weakAreas.append(AITimoMath.AILearningProgress.WeakArea(
                    subject: lesson.subject,
                    conceptScore: lesson.accuracy,
                    lastPracticed: completedAt
                ))
            }
        } else if lesson.accuracy > 0.8 {
            // Performance is good, consider removing from weak areas
            if let index = learningProgress.weakAreas.firstIndex(where: { $0.subject == lesson.subject }) {
                learningProgress.weakAreas.remove(at: index)
            }
        } else {
            // Performance is moderate, update timestamp but keep as weak area
            if let index = learningProgress.weakAreas.firstIndex(where: { $0.subject == lesson.subject }) {
                learningProgress.weakAreas[index].lastPracticed = completedAt
            }
        }
    }
    
    /// Generate performance insights from a completed lesson
    private func generatePerformanceInsights(from lesson: Lesson) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []
        
        // Add basic performance insight
        insights.append(PerformanceInsight(
            type: .accuracyReport,
            subject: lesson.subject,
            value: lesson.accuracy,
            timestamp: Date()
        ))
        
        // Add speed insight
        insights.append(PerformanceInsight(
            type: .speedReport,
            subject: lesson.subject,
            value: Float(lesson.responseTime),
            timestamp: Date()
        ))
        
        // Add insight about specific question types (simplified)
        if lesson.accuracy < 0.5 {
            insights.append(PerformanceInsight(
                type: .weakConceptIdentified,
                subject: lesson.subject,
                value: lesson.accuracy,
                timestamp: Date()
            ))
        } else if lesson.accuracy > 0.9 {
            insights.append(PerformanceInsight(
                type: .masteryAchieved,
                subject: lesson.subject,
                value: lesson.accuracy,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    /// Store performance insights for later analysis
    private func storePerformanceInsights(_ insights: [PerformanceInsight], for userId: UUID) {
        // In a real implementation, this would store insights in the database
        // For this prototype, we'll just print them
        for insight in insights {
            print("User \(userId): \(insight.type) - \(insight.subject) - \(insight.value)")
        }
    }
    
    /// Group question responses by subject
    private func groupResponsesBySubject(
        userId: UUID,
        responses: [Lesson.QuestionResponse]
    ) async -> [Lesson.Subject: [Lesson.QuestionResponse]] {
        var subjectResponses: [Lesson.Subject: [Lesson.QuestionResponse]] = [:]
        
        // Attempt to fetch questions to determine their subjects
        // This is a simplified version - in production, it would be more efficient
        for response in responses {
            // Try to get the question
            if let question = try? await QuestionService.shared.getQuestion(id: response.questionId) {
                // Add to the appropriate subject group
                var subjectGroup = subjectResponses[question.subject] ?? []
                subjectGroup.append(response)
                subjectResponses[question.subject] = subjectGroup
            }
        }
        
        return subjectResponses
    }
    
    /// Calculate appropriate difficulty level for a weak area
    private func calculateDifficultyForWeakArea(_ weakArea: AITimoMath.AILearningProgress.WeakArea) -> Int {
        // If very weak in a subject, start with easiest level
        if weakArea.conceptScore < 0.4 {
            return 1
        }
        // If moderately weak, use level 2
        else if weakArea.conceptScore < 0.6 {
            return 2
        }
        // If only slightly weak, use level 3
        else {
            return 3
        }
    }
    
    /// Get current difficulty level for a subject based on history
    private func getCurrentDifficultyForSubject(
        _ subject: Lesson.Subject,
        in learningProgress: AITimoMath.AILearningProgress
    ) -> Int {
        // Look for the most recent lesson in this subject
        for lesson in learningProgress.lessonHistory.reversed() where lesson.subject == subject {
            return lesson.nextDifficulty
        }
        
        // If no history for this subject, start with difficulty 1
        return 1
    }
    
    /// Analyze progress trends by subject
    private func analyzeRecentProgressTrend(_ learningProgress: AITimoMath.AILearningProgress) -> [Lesson.Subject: Float] {
        var trends: [Lesson.Subject: Float] = [:]
        
        // Group lessons by subject
        var lessonsBySubject: [Lesson.Subject: [AITimoMath.AILearningProgress.LessonProgress]] = [:]
        for lesson in learningProgress.lessonHistory {
            var subjectLessons = lessonsBySubject[lesson.subject] ?? []
            subjectLessons.append(lesson)
            lessonsBySubject[lesson.subject] = subjectLessons
        }
        
        // Calculate trend for each subject with enough data
        for (subject, lessons) in lessonsBySubject where lessons.count >= 3 {
            // Get up to 5 most recent lessons
            let recentLessons = Array(lessons.suffix(5))
            
            // Calculate linear regression for accuracy trend
            var sumX: Float = 0.0
            var sumY: Float = 0.0
            var sumXY: Float = 0.0
            var sumXSquared: Float = 0.0
            
            let n = Float(recentLessons.count)
            
            for (i, lesson) in recentLessons.enumerated() {
                let x = Float(i)
                let y = lesson.accuracy
                
                sumX += x
                sumY += y
                sumXY += x * y
                sumXSquared += x * x
            }
            
            // Calculate slope of the trend line
            // Ensure denominator isn't zero
            if n * sumXSquared - sumX * sumX != 0 {
                let slope = (n * sumXY - sumX * sumY) / (n * sumXSquared - sumX * sumX)
                trends[subject] = slope
            } else {
                trends[subject] = 0.0
            }
        }
        
        return trends
    }
    
    /// Calculate response time trend
    private func calculateResponseTimeTrend(_ lessonHistory: [AITimoMath.AILearningProgress.LessonProgress]) -> Float {
        // Need at least 2 lessons to calculate trend
        guard lessonHistory.count >= 2 else {
            return 0.0
        }
        
        let recentLessons = lessonHistory.suffix(5)
        
        // Calculate linear regression for response time
        var sumX: Float = 0.0
        var sumY: Float = 0.0
        var sumXY: Float = 0.0
        var sumXSquared: Float = 0.0
        
        let n = Float(recentLessons.count)
        
        for (i, lesson) in recentLessons.enumerated() {
            let x = Float(i)
            let y = Float(lesson.responseTime)
            
            sumX += x
            sumY += y
            sumXY += x * y
            sumXSquared += x * x
        }
        
        // Calculate slope (negative slope is good - getting faster)
        if n * sumXSquared - sumX * sumX != 0 {
            let slope = (n * sumXY - sumX * sumY) / (n * sumXSquared - sumX * sumX)
            // Invert the sign so positive = getting faster
            return -slope
        }
        
        return 0.0
    }
    
    /// Calculate how quickly difficulty is increasing
    private func calculateDifficultyProgression(_ lessonHistory: [AITimoMath.AILearningProgress.LessonProgress]) -> Float {
        let recentLessons = lessonHistory.suffix(5)
        
        // Calculate linear regression for difficulty
        var sumX: Float = 0.0
        var sumY: Float = 0.0
        var sumXY: Float = 0.0
        var sumXSquared: Float = 0.0
        
        let n = Float(recentLessons.count)
        
        for (i, lesson) in recentLessons.enumerated() {
            let x = Float(i)
            let y = Float(lesson.nextDifficulty)
            
            sumX += x
            sumY += y
            sumXY += x * y
            sumXSquared += x * x
        }
        
        // Calculate slope (positive = difficulty increasing)
        if n * sumXSquared - sumX * sumX != 0 {
            return (n * sumXY - sumX * sumY) / (n * sumXSquared - sumX * sumX)
        }
        
        return 0.0
    }
}

// MARK: - Supporting Types

extension StudentPerformanceTracker {
    /// Type of learning path recommendation
    public enum RecommendationType {
        /// Focused practice on weak areas
        case reinforcement
        
        /// Advancement to more challenging content
        case advancement
        
        /// Exploration of new topics
        case exploration
    }
    
    /// Recommendation for a student's learning path
    public struct LearningPathRecommendation {
        /// Subject of the recommendation
        public let subject: Lesson.Subject
        
        /// Type of recommendation
        public let recommendationType: RecommendationType
        
        /// Recommended difficulty level (1-4)
        public let difficulty: Int
    }
    
    /// Types of performance insights
    public enum InsightType {
        case accuracyReport
        case speedReport
        case weakConceptIdentified
        case masteryAchieved
    }
    
    /// Insight about student performance
    public struct PerformanceInsight {
        /// Type of insight
        public let type: InsightType
        
        /// Subject the insight relates to
        public let subject: Lesson.Subject
        
        /// Value associated with the insight
        public let value: Float
        
        /// When the insight was generated
        public let timestamp: Date
    }
    
    /// Metrics for learning speed
    public struct LearningSpeedMetrics {
        /// Average response time in seconds
        public let averageResponseTime: TimeInterval
        
        /// Trend in response time (positive = getting faster)
        public let responseTimeTrend: Float
        
        /// Speed of mastery acquisition (higher = faster mastery)
        public let masterySpeed: Float
        
        /// Initialize with default values
        public init(
            averageResponseTime: TimeInterval = 0.0,
            responseTimeTrend: Float = 0.0,
            masterySpeed: Float = 1.0
        ) {
            self.averageResponseTime = averageResponseTime
            self.responseTimeTrend = responseTimeTrend
            self.masterySpeed = masterySpeed
        }
    }
} 