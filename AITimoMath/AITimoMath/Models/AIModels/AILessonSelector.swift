import Foundation

/// AI Lesson Selector using collaborative filtering and decision trees
/// to recommend personalized lessons based on student performance
public class AILessonSelector {
    /// Singleton instance for app-wide use
    public static let shared = AILessonSelector()
    
    /// Initialize the lesson selector
    private init() {}
    
    // MARK: - Type Aliases
    private typealias LearningProgress = AITimoMath.AILearningProgress
    
    /// Recommend the next set of questions for a learning session
    /// - Parameters:
    ///   - user: The student user to generate recommendations for
    ///   - learningProgress: The student's AI learning progress
    ///   - questionCount: Number of questions to recommend
    /// - Returns: Array of recommended question IDs
    public func recommendQuestions(
        for user: User,
        learningProgress: AITimoMath.AILearningProgress,
        questionCount: Int = 10
    ) async throws -> [UUID] {
        // Load all available questions
        let allQuestions = try await QuestionService.shared.loadQuestions()
        
        // Analyze weak areas to prioritize subjects
        let subjectPriorities = analyzeWeakAreas(learningProgress.weakAreas)
        
        // Get user's ability level (based on past performance)
        let abilityLevel = estimateAbilityLevel(learningProgress)
        
        // Calculate difficulty target for the next lesson
        let difficultyTarget = calculateDifficultyTarget(
            currentLevel: learningProgress.lessonHistory.last?.nextDifficulty ?? 1,
            abilityLevel: abilityLevel
        )
        
        // Filter questions by subject priority and difficulty
        var candidateQuestions = filterCandidateQuestions(
            questions: allQuestions,
            subjectPriorities: subjectPriorities,
            difficultyTarget: difficultyTarget
        )
        
        // Remove recently completed questions to avoid repetition
        let recentQuestions = getRecentlyCompletedQuestions(learningProgress, limit: 50)
        candidateQuestions = candidateQuestions.filter { !recentQuestions.contains($0.id) }
        
        // If we still don't have enough questions, broaden our criteria
        if candidateQuestions.count < questionCount {
            candidateQuestions = allQuestions.filter { !recentQuestions.contains($0.id) }
        }
        
        // Apply collaborative filtering to select questions similar students found helpful
        let recommendedQuestions = applyCollaborativeFiltering(
            candidateQuestions: candidateQuestions,
            userProgress: learningProgress
        )
        
        // Return the top N question IDs
        return Array(recommendedQuestions.prefix(questionCount).map { $0.id })
    }
    
    /// Recommend a full lesson with appropriate subject and difficulty
    /// - Parameters:
    ///   - user: The student user
    ///   - learningProgress: The student's AI learning progress
    /// - Returns: A configured lesson with selected questions
    public func recommendLesson(
        for user: User,
        learningProgress: AITimoMath.AILearningProgress
    ) async throws -> Lesson {
        // Analyze weak areas to select a subject for the lesson
        let subject = selectSubjectForLesson(weakAreas: learningProgress.weakAreas)
        
        // Create a new lesson with the selected subject
        var lesson = Lesson(userId: user.id, subject: subject)
        
        // Get appropriate question count based on user's learning goal
        let questionCount = min(max(5, user.learningGoal), 20)
        
        // Get recommended questions
        let questionIds = try await recommendQuestions(
            for: user,
            learningProgress: learningProgress,
            questionCount: questionCount
        )
        
        // Add questions to the lesson
        lesson.questions = questionIds
        
        return lesson
    }
    
    /// Recommends the next lesson based on the student's learning profile and history
    /// - Parameter learningProgress: Student's current learning profile and history
    /// - Returns: The recommended lesson for the student to take next
    public func recommendNextLesson(learningProgress: AITimoMath.AILearningProgress) -> Lesson {
        // Implementation of recommendNextLesson method
        // This method should return the recommended lesson for the student to take next
        // based on the student's learning profile and history
        // For now, we'll return a placeholder lesson
        return Lesson(userId: UUID(), subject: .logicalThinking)
    }
    
    /// Generates a customized learning path for a student
    /// - Parameters:
    ///   - learningProgress: Student's current learning progress
    ///   - count: Number of lessons to include in the learning path
    /// - Returns: A sequence of recommended lessons
    public func generateLearningPath(
        learningProgress: AITimoMath.AILearningProgress,
        count: Int = 5
    ) -> [Lesson] {
        // Implementation of generateLearningPath method
        // This method should return a sequence of recommended lessons for the student
        // based on the student's current learning progress
        // For now, we'll return an empty array
        return []
    }
    
    /// Get recently completed questions to avoid repetition
    private func getRecentlyCompletedQuestions(_ learningProgress: AITimoMath.AILearningProgress, limit: Int) -> Set<UUID> {
        var recentQuestions = Set<UUID>()
        
        // Extract question IDs from recent lessons
        for lesson in learningProgress.lessonHistory.suffix(10) {
            // We would need to fetch the actual lesson to get its questions
            // This is a simplified version that looks at lesson IDs instead
            recentQuestions.insert(lesson.lessonId)
        }
        
        return recentQuestions
    }
    
    /// Apply collaborative filtering to select the most relevant questions
    private func applyCollaborativeFiltering(
        candidateQuestions: [Question],
        userProgress: AITimoMath.AILearningProgress
    ) -> [Question] {
        // In a real implementation, this would compare with similar students
        // and analyze which questions were most effective for them
        
        // For now, we'll use a simpler approach that simulates collaborative filtering
        // by weighing questions based on their subject's alignment with weak areas
        
        let weakSubjects = userProgress.weakAreas.map { $0.subject }
        let weakSubjectsSet = Set(weakSubjects)
        
        return candidateQuestions.sorted { q1, q2 in
            // Prioritize questions in weak subjects
            let q1InWeakSubject = weakSubjectsSet.contains(q1.subject)
            let q2InWeakSubject = weakSubjectsSet.contains(q2.subject)
            
            if q1InWeakSubject != q2InWeakSubject {
                return q1InWeakSubject
            }
            
            // If both questions are in weak subjects, prioritize questions with hints
            if q1.hint != nil && q2.hint == nil {
                return true
            } else if q1.hint == nil && q2.hint != nil {
                return false
            }
            
            // Otherwise, maintain existing order
            return true
        }
    }
    
    /// Analyze weak areas to prioritize subjects for recommendations
    /// - Parameter weakAreas: Array of weak areas from learning progress
    /// - Returns: Dictionary mapping subjects to priority scores (higher = higher priority)
    private func analyzeWeakAreas(_ weakAreas: [AITimoMath.AILearningProgress.WeakArea]) -> [Lesson.Subject: Float] {
        var priorities: [Lesson.Subject: Float] = [:]
        
        // Start with equal priority for all subjects
        Lesson.Subject.allCases.forEach { subject in
            priorities[subject] = 1.0
        }
        
        // Increase priority for weak areas
        for weakArea in weakAreas {
            // Lower concept score means higher priority
            let priorityBoost = 2.0 - (weakArea.conceptScore * 2.0)
            priorities[weakArea.subject, default: 1.0] += priorityBoost
            
            // Adjust priority based on how recently it was practiced
            // (More recent = lower additional priority)
            let daysSinceLastPractice = daysBetween(weakArea.lastPracticed, Date())
            let recencyBoost = min(Float(daysSinceLastPractice) * 0.05, 0.5)
            priorities[weakArea.subject, default: 1.0] += recencyBoost
        }
        
        return priorities
    }
    
    /// Calculate days between two dates
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    /// Estimate student's ability level based on past performance
    private func estimateAbilityLevel(_ learningProgress: AITimoMath.AILearningProgress) -> Float {
        // If no history, assume average ability
        guard !learningProgress.lessonHistory.isEmpty else {
            return 0.0
        }
        
        // Calculate weighted average of recent lesson performances
        let recentLessons = learningProgress.lessonHistory.suffix(5)
        var totalWeight: Float = 0.0
        var weightedAccuracy: Float = 0.0
        
        for (index, lesson) in recentLessons.enumerated() {
            // More recent lessons get higher weight
            let weight: Float = Float(index + 1)
            weightedAccuracy += lesson.accuracy * weight
            totalWeight += weight
        }
        
        // Convert to IRT ability scale (approximately -3 to +3)
        let averageAccuracy = weightedAccuracy / totalWeight
        return (averageAccuracy * 6.0) - 3.0
    }
    
    /// Calculate target difficulty for the next lesson
    private func calculateDifficultyTarget(currentLevel: Int, abilityLevel: Float) -> Int {
        // Convert ability level to recommended difficulty level
        let recommendedLevel = IRTModel().convertIRTDifficultyToLevel(abilityLevel)
        
        // Don't jump more than one level at a time
        if recommendedLevel > currentLevel {
            return min(currentLevel + 1, recommendedLevel)
        } else if recommendedLevel < currentLevel {
            return max(currentLevel - 1, recommendedLevel)
        } else {
            return currentLevel
        }
    }
    
    /// Filter questions based on subject priorities and target difficulty
    private func filterCandidateQuestions(
        questions: [Question],
        subjectPriorities: [Lesson.Subject: Float],
        difficultyTarget: Int
    ) -> [Question] {
        // Calculate acceptable difficulty range
        let minDifficulty = max(1, difficultyTarget - 1)
        let maxDifficulty = min(4, difficultyTarget + 1)
        
        // Filter questions within difficulty range
        let filteredByDifficulty = questions.filter { 
            ($0.difficulty >= minDifficulty) && ($0.difficulty <= maxDifficulty)
        }
        
        // Sort by subject priority (higher priority first)
        return filteredByDifficulty.sorted { q1, q2 in
            let priority1 = subjectPriorities[q1.subject] ?? 1.0
            let priority2 = subjectPriorities[q2.subject] ?? 1.0
            
            if abs(priority1 - priority2) > 0.1 {
                // If priorities differ significantly, sort by priority
                return priority1 > priority2
            } else {
                // If priorities are similar, sort by difficulty match
                let diff1 = abs(q1.difficulty - difficultyTarget)
                let diff2 = abs(q2.difficulty - difficultyTarget)
                return diff1 < diff2
            }
        }
    }
    
    /// Select a subject for the next lesson based on weak areas
    private func selectSubjectForLesson(weakAreas: [AITimoMath.AILearningProgress.WeakArea]) -> Lesson.Subject {
        // If no weak areas, select a random subject
        guard !weakAreas.isEmpty else {
            let allSubjects = [
                Lesson.Subject.logicalThinking,
                Lesson.Subject.arithmetic,
                Lesson.Subject.numberTheory,
                Lesson.Subject.geometry,
                Lesson.Subject.combinatorics
            ]
            return allSubjects.randomElement() ?? .logicalThinking
        }
        
        // Sort weak areas by concept score (ascending) and how recently practiced (descending)
        let sortedWeakAreas = weakAreas.sorted { area1, area2 in
            if abs(area1.conceptScore - area2.conceptScore) > 0.1 {
                return area1.conceptScore < area2.conceptScore
            } else {
                return area1.lastPracticed < area2.lastPracticed
            }
        }
        
        // Select the top weak area subject
        return sortedWeakAreas.first?.subject ?? .logicalThinking
    }
}

// MARK: - Helper Extensions

extension Lesson.Subject: CaseIterable {
    public static var allCases: [Lesson.Subject] {
        return [.logicalThinking, .arithmetic, .numberTheory, .geometry, .combinatorics]
    }
} 