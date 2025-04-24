import Foundation

/// Integrates Elo Rating, Bayesian Knowledge Tracing (BKT), and Item Response Theory (IRT)
/// to provide adaptive difficulty adjustments for lessons
public class AdaptiveDifficultyEngine {
    /// Singleton instance for app-wide use
    public static let shared = AdaptiveDifficultyEngine()
    
    /// The Elo Rating model for adjusting difficulty
    private let eloModel = EloRatingModel()
    
    /// The BKT model for concept mastery
    private let bktModel = BKTModel()
    
    /// The IRT model for difficulty mapping
    private let irtModel = IRTModel()
    
    /// Initialize the adaptive difficulty engine
    private init() {}
    
    // MARK: - Type Aliases
    private typealias LearningProgress = AITimoMath.AILearningProgress
    
    /// Calculate next lesson difficulty based on student performance
    /// - Parameters:
    ///   - learningProgress: The student's learning progress
    ///   - lessonPerformance: Recent lesson performance
    /// - Returns: Recommended difficulty level (1-4) for the next lesson
    public func calculateNextLessonDifficulty(
        learningProgress: AITimoMath.AILearningProgress,
        lessonPerformance: Lesson.QuestionResponse
    ) -> Int {
        // Get current Elo rating (or default if none exists)
        let currentEloRating = getCurrentEloRating(learningProgress)
        
        // Get question parameters (would be loaded from question data)
        let questionParameters = getQuestionParameters(questionId: lessonPerformance.questionId)
        
        // Calculate new Elo rating based on performance
        let newEloRating = eloModel.calculateNewStudentRating(
            currentRating: currentEloRating,
            questionDifficulty: questionParameters.eloRating,
            isCorrect: lessonPerformance.isCorrect,
            responseTime: lessonPerformance.responseTime
        )
        
        // Update ability estimate using IRT
        let currentAbility = convertEloToIRTAbility(currentEloRating)
        let newAbility = irtModel.estimateAbility(
            currentAbility: currentAbility,
            questionParameters: questionParameters.irt,
            isCorrect: lessonPerformance.isCorrect
        )
        
        // Update concept mastery using BKT
        let conceptId = getConceptIdForQuestion(questionId: lessonPerformance.questionId)
        let currentMastery = getCurrentConceptMastery(
            learningProgress: learningProgress,
            conceptId: conceptId
        )
        let newMastery = bktModel.updateKnowledge(
            priorKnowledge: currentMastery,
            isCorrect: lessonPerformance.isCorrect
        )
        
        // Weight the recommendations from each model
        let eloDifficulty = eloModel.convertEloToDifficultyLevel(newEloRating)
        let irtDifficulty = irtModel.convertIRTDifficultyToLevel(newAbility)
        let bktDifficulty = bktModel.isConceptMastered(knowledge: newMastery) ? 
            getCurrentDifficulty(learningProgress) + 1 : 
            getCurrentDifficulty(learningProgress)
        
        // Combine models with weights (Elo: 50%, IRT: 30%, BKT: 20%)
        let weightedDifficulty = (Float(eloDifficulty) * 0.5) + 
                               (Float(irtDifficulty) * 0.3) + 
                               (Float(bktDifficulty) * 0.2)
        
        // Round to nearest integer and ensure within valid range
        let nextDifficulty = min(4, max(1, Int(round(weightedDifficulty))))
        
        // Don't jump more than one level at a time for smoothness
        let currentDifficulty = getCurrentDifficulty(learningProgress)
        if nextDifficulty > currentDifficulty {
            return min(currentDifficulty + 1, nextDifficulty)
        } else if nextDifficulty < currentDifficulty {
            return max(currentDifficulty - 1, nextDifficulty)
        } else {
            return currentDifficulty
        }
    }
    
    /// Calculate new difficulty level after completing a full lesson
    /// - Parameters:
    ///   - learningProgress: The student's learning progress
    ///   - completedLesson: The lesson that was just completed
    /// - Returns: Recommended difficulty for the next session
    public func calculateDifficultyAfterLesson(
        learningProgress: AITimoMath.AILearningProgress,
        completedLesson: Lesson
    ) -> Int {
        // If accuracy is very high, consider increasing difficulty
        if completedLesson.accuracy >= 0.9 {
            let currentDifficulty = getCurrentDifficulty(learningProgress)
            return min(4, currentDifficulty + 1)
        }
        // If accuracy is very low, consider decreasing difficulty
        else if completedLesson.accuracy < 0.4 {
            let currentDifficulty = getCurrentDifficulty(learningProgress)
            return max(1, currentDifficulty - 1)
        }
        // If accuracy is moderate, maintain current difficulty but adjust based on trend
        else {
            // Analyze trend from recent lessons
            let trend = analyzePerformanceTrend(learningProgress)
            let currentDifficulty = getCurrentDifficulty(learningProgress)
            
            if trend > 0.2 {
                // Improving trend, consider increasing difficulty
                return min(4, currentDifficulty + 1)
            } else if trend < -0.2 {
                // Declining trend, consider decreasing difficulty
                return max(1, currentDifficulty - 1)
            } else {
                // Stable trend, maintain current difficulty
                return currentDifficulty
            }
        }
    }
    
    /// Get current difficulty level from learning progress
    private func getCurrentDifficulty(_ learningProgress: AITimoMath.AILearningProgress) -> Int {
        return learningProgress.lessonHistory.last?.nextDifficulty ?? 1
    }
    
    /// Get current Elo rating from learning progress
    private func getCurrentEloRating(_ learningProgress: AITimoMath.AILearningProgress) -> Float {
        // In a real implementation, this would be stored in the learning progress
        // For now, we'll estimate it based on the current difficulty level
        let currentDifficulty = getCurrentDifficulty(learningProgress)
        return eloModel.convertDifficultyLevelToElo(currentDifficulty)
    }
    
    /// Convert Elo rating to IRT ability level
    private func convertEloToIRTAbility(_ eloRating: Float) -> Float {
        // Convert Elo (typically 0-3000) to IRT ability (typically -3 to +3)
        // This is an approximation - actual conversion would depend on data analysis
        return ((eloRating - 1200) / 400.0)
    }
    
    /// Get concept mastery level for a specific concept
    private func getCurrentConceptMastery(
        learningProgress: AITimoMath.AILearningProgress,
        conceptId: String
    ) -> Float {
        // In a real implementation, this would look up the mastery level from stored data
        // For this implementation, we'll estimate based on weak areas
        
        // Check if concept's subject is in weak areas
        let conceptSubject = getSubjectForConcept(conceptId)
        for weakArea in learningProgress.weakAreas {
            if weakArea.subject.rawValue == conceptSubject {
                return weakArea.conceptScore
            }
        }
        
        // Default value if no specific data is available
        return 0.7
    }
    
    /// Get relevant parameters for a question
    private func getQuestionParameters(questionId: UUID) -> (eloRating: Float, irt: IRTModel.Parameters, bkt: BKTModel.Parameters) {
        // In a real implementation, this would fetch parameters from the question database
        // For now, return default values
        
        // Create default parameters
        let eloRating: Float = 1200.0
        let irtParams = IRTModel.Parameters(
            discrimination: 1.0,
            difficulty: 0.0,
            guessing: 0.25
        )
        let bktParams = BKTModel.Parameters(
            pLearn: 0.4,
            pGuess: 0.25,
            pSlip: 0.1,
            pKnown: 0.5,
            pForget: 0.05
        )
        
        return (eloRating, irtParams, bktParams)
    }
    
    /// Analyze performance trend from recent lessons
    private func analyzePerformanceTrend(_ learningProgress: AITimoMath.AILearningProgress) -> Float {
        // Need at least 2 lessons to establish a trend
        guard learningProgress.lessonHistory.count >= 2 else {
            return 0.0
        }
        
        // Get last 5 lessons (or fewer if not available)
        let recentLessons = learningProgress.lessonHistory.suffix(5)
        
        // Calculate linear regression slope of accuracy over time
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
        let slope = (n * sumXY - sumX * sumY) / (n * sumXSquared - sumX * sumX)
        
        return slope
    }
    
    /// Get concept ID for a question (simplified)
    private func getConceptIdForQuestion(questionId: UUID) -> String {
        // In a real implementation, this would look up the concept ID from the question
        // For now, return a placeholder value
        return questionId.uuidString
    }
    
    /// Get subject for a concept (simplified)
    private func getSubjectForConcept(_ conceptId: String) -> String {
        // In a real implementation, this would look up the subject from the concept
        // For now, return a placeholder value
        return "logical_thinking"
    }
} 