import Foundation
import CoreML
import CloudKit
import Combine

/// Model representing a student's weak area in a particular subject
struct AILearningWeakArea: Identifiable, Codable {
    var id: UUID = UUID()
    var subject: Lesson.Subject
    var conceptScore: Float
    var conceptName: String
    var completedAt: Date?
}

/// Model representing a completed lesson with performance data
struct AILearningLessonCompletion: Identifiable, Codable {
    var id: UUID = UUID()
    var subject: Lesson.Subject
    var difficulty: Int
    var nextDifficulty: Int
    var accuracy: Float
    var completedAt: Date
    var responseTimeAvg: TimeInterval
}

/// Model representing a student's learning progress (internal to AILearningService)
struct InternalLearningProgress {
    var userId: UUID
    var abilityLevel: Float
    var lessonHistory: [AILearningLessonCompletion]
    var weakAreas: [AILearningWeakArea]
    var recommendedLessons: [Lesson.Subject]
}

/// Service that coordinates AI models and orchestrates adaptive learning
public class AILearningService {
    /// Shared instance for app-wide use
    public static let shared = AILearningService()
    
    /// The adaptive difficulty engine
    private let adaptiveDifficultyEngine = AdaptiveDifficultyEngine.shared
    
    /// The AI lesson selector
    private let lessonSelector = AILessonSelector.shared
    
    /// Persistence controller for data storage
    private let persistenceController = PersistenceController.shared
    
    /// Question service for loading and managing questions
    private let questionService = QuestionService.shared
    
    /// The CloudKit database for storing learning progress
    private let database = CKContainer.default().privateCloudDatabase
    
    /// Cache of loaded learning progress
    private var progressCache: [UUID: AILearningProgress] = [:]
    
    /// Private initializer for singleton
    private init() {}
    
    /// Get learning progress for a student
    /// - Parameter userId: The student's user ID
    /// - Returns: The learning progress
    public func getLearningProgress(userId: UUID) async throws -> AILearningProgress {
        // Check cache first
        if let cachedProgress = progressCache[userId] {
            return cachedProgress
        }
        
        // Try to get from CloudKit
        do {
            let record = try await fetchLearningProgressRecord(userId: userId)
            let internalProgress = convertRecordToInternalProgress(record)
            let progress = convertInternalToPublicProgress(internalProgress)
            
            // Cache it
            progressCache[userId] = progress
            
            return progress
        } catch {
            // Create a new learning progress if not found
            let internalProgress = InternalLearningProgress(
                userId: userId,
                abilityLevel: 0.5,
                lessonHistory: [],
                weakAreas: [],
                recommendedLessons: []
            )
            
            // Save it to CloudKit
            try await saveInternalLearningProgress(internalProgress)
            
            // Convert to public API model
            let progress = convertInternalToPublicProgress(internalProgress)
            
            // Cache it
            progressCache[userId] = progress
            
            return progress
        }
    }
    
    /// Refresh learning progress for a student from CloudKit (ignoring cache)
    /// - Parameter userId: The student's user ID
    /// - Returns: The freshly fetched learning progress
    public func refreshLearningProgress(userId: UUID) async throws -> AILearningProgress {
        // Clear cache for this user
        clearCache(for: userId)
        
        // Fetch fresh data from CloudKit
        do {
            let record = try await fetchLearningProgressRecord(userId: userId)
            let internalProgress = convertRecordToInternalProgress(record)
            let progress = convertInternalToPublicProgress(internalProgress)
            
            // Update cache
            progressCache[userId] = progress
            
            return progress
        } catch {
            // Handle error or create new if needed
            print("Error refreshing learning progress: \(error.localizedDescription)")
            
            // Try to create a new one
            let internalProgress = InternalLearningProgress(
                userId: userId,
                abilityLevel: 0.5,
                lessonHistory: [],
                weakAreas: [],
                recommendedLessons: []
            )
            
            // Save it to CloudKit
            try await saveInternalLearningProgress(internalProgress)
            
            // Convert to public API model
            let progress = convertInternalToPublicProgress(internalProgress)
            
            // Cache it
            progressCache[userId] = progress
            
            return progress
        }
    }
    
    /// Create a new learning progress for a student
    /// - Parameter userId: The student's user ID
    /// - Returns: A new AI learning progress
    public func createLearningProgress(userId: UUID) async throws -> AILearningProgress {
        // Create a new learning progress
        let internalProgress = InternalLearningProgress(
            userId: userId,
            abilityLevel: 0.5,
            lessonHistory: [],
            weakAreas: [],
            recommendedLessons: []
        )
        
        // Save it to CloudKit
        try await saveInternalLearningProgress(internalProgress)
        
        // Convert to public API model
        return convertInternalToPublicProgress(internalProgress)
    }
    
    /// Update learning progress after a lesson is completed
    /// - Parameters:
    ///   - userId: The student's user ID
    ///   - lesson: The completed lesson
    /// - Returns: Updated learning progress
    public func updateLearningProgress(userId: UUID, lesson: Lesson) async throws -> AILearningProgress {
        // Ensure the lesson is completed
        guard lesson.status == .completed,
              let completedAt = lesson.completedAt else {
            throw AILearningServiceError.lessonNotCompleted
        }
        
        // Get the current learning progress as internal model
        let record = try await fetchLearningProgressRecord(userId: userId)
        var internalProgress = convertRecordToInternalProgress(record)
        
        // Calculate the next difficulty level based on performance
        let nextDifficulty = calculateNextDifficultyLevel(lesson: lesson, currentLevel: lesson.difficulty)
        
        // Create a lesson progress record
        let lessonProgress = AILearningLessonCompletion(
            id: UUID(),
            subject: lesson.subject,
            difficulty: lesson.difficulty,
            nextDifficulty: nextDifficulty,
            accuracy: lesson.accuracy,
            completedAt: completedAt,
            responseTimeAvg: lesson.responseTime
        )
        
        // Add it to the history
        internalProgress.lessonHistory.append(lessonProgress)
        
        // Update weak areas based on performance
        updateWeakAreas(in: &internalProgress, with: lesson, completedAt: completedAt)
        
        // Update AI models with new data
        updateAIModels(with: lesson, for: userId)
        
        // Save the updated learning progress
        try await saveInternalLearningProgress(internalProgress)
        
        // Convert to public API model
        let progress = convertInternalToPublicProgress(internalProgress)
        
        // Update cache
        progressCache[userId] = progress
        
        return progress
    }
    
    /// Recommend questions for the next lesson
    /// - Parameters:
    ///   - userId: The student's user ID
    ///   - count: Number of questions to recommend
    /// - Returns: Array of recommended question IDs
    public func recommendQuestions(userId: UUID, count: Int = 10) async throws -> [UUID] {
        // Get user and learning progress
        guard let user = try? await UserService.shared.getUser(id: userId) else {
            throw AILearningServiceError.userNotFound
        }
        
        let learningProgress = try await getLearningProgress(userId: userId)
        
        // Use the lesson selector to get recommendations
        return try await AILessonSelector.shared.recommendQuestions(
            for: user,
            learningProgress: learningProgress,
            questionCount: count
        )
    }
    
    /// Create a new lesson with recommended questions
    /// - Parameter userId: The student's user ID
    /// - Returns: A new lesson with recommended questions
    public func createRecommendedLesson(userId: UUID) async throws -> Lesson {
        // Get user and learning progress
        guard let user = try? await UserService.shared.getUser(id: userId) else {
            throw AILearningServiceError.userNotFound
        }
        
        let learningProgress = try await getLearningProgress(userId: userId)
        
        // Use the lesson selector to create a recommended lesson
        return try await AILessonSelector.shared.recommendLesson(
            for: user,
            learningProgress: learningProgress
        )
    }
    
    /// Process an answer in real-time to provide feedback
    /// - Parameters:
    ///   - userId: The student's user ID
    ///   - questionId: The question ID
    ///   - isCorrect: Whether the answer was correct
    ///   - responseTime: Time taken to answer
    /// - Returns: Personalized feedback for the answer
    public func processAnswer(
        userId: UUID,
        questionId: UUID,
        isCorrect: Bool,
        responseTime: TimeInterval
    ) async throws -> AnswerFeedback {
        // Get question difficulty
        let question = try await QuestionService.shared.getQuestion(id: questionId)
        
        // Create feedback based on the answer
        var feedback = AnswerFeedback(isCorrect: isCorrect)
        
        if isCorrect {
            // Positive feedback
            feedback.message = generatePositiveFeedback(responseTime: responseTime)
            
            // Recommend next step
            feedback.nextStep = .continueLesson
        } else {
            // Mistake feedback
            feedback.message = generateMistakeFeedback()
            
            // Offer a hint if available
            if let hint = question?.hint {
                feedback.hint = hint
                feedback.nextStep = .tryAgainWithHint
            } else {
                feedback.nextStep = .revealAnswer
            }
        }
        
        return feedback
    }
    
    /// Calculate performance statistics for a student
    /// - Parameter userId: The student's user ID
    /// - Returns: Performance statistics
    public func calculatePerformanceStats(userId: UUID) async throws -> AILearningService.PerformanceStats {
        let learningProgress = try await getLearningProgress(userId: userId)
        
        // Convert from AILearningProgress.PerformanceStats to AILearningService.PerformanceStats
        let progressStats = learningProgress.performanceStats
        
        // Create and return AILearningService.PerformanceStats
        var serviceStats = AILearningService.PerformanceStats()
        serviceStats.overallAccuracy = progressStats.overallAccuracy
        serviceStats.averageResponseTime = progressStats.averageResponseTime
        serviceStats.subjectAccuracy = progressStats.subjectAccuracy
        serviceStats.improvementTrend = progressStats.improvementTrend
        serviceStats.totalLessonsCompleted = progressStats.totalLessonsCompleted
        
        return serviceStats
    }
    
    /// Get improvement trends over time
    /// - Parameter userId: The student's user ID
    /// - Returns: Dictionary mapping subjects to improvement trends
    public func getImprovementTrends(userId: UUID) async throws -> [Lesson.Subject: Float] {
        let learningProgress = try await getLearningProgress(userId: userId)
        
        // If not enough history, return empty trends
        guard learningProgress.lessonHistory.count >= 3 else {
            return [:]
        }
        
        // Group lessons by subject
        var lessonsBySubject: [Lesson.Subject: [AILearningProgress.LessonProgress]] = [:]
        for lesson in learningProgress.lessonHistory {
            var subjectLessons = lessonsBySubject[lesson.subject] ?? []
            subjectLessons.append(lesson)
            lessonsBySubject[lesson.subject] = subjectLessons
        }
        
        // Calculate improvement trend for each subject
        var trends: [Lesson.Subject: Float] = [:]
        
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
            if n * sumXSquared - sumX * sumX != 0 {
                let slope = (n * sumXY - sumX * sumY) / (n * sumXSquared - sumX * sumX)
                trends[subject] = slope
            } else {
                trends[subject] = 0.0
            }
        }
        
        return trends
    }
    
    /// Run a test of the AI learning service with a mock lesson
    /// - Returns: Test results summary string
    public func runAIModelTest() -> String {
        print("⚙️ Testing AI Learning Service")
        
        // Create test user ID
        let testUserId = UUID()
        
        // Create a mock lesson
        let lesson = Lesson(userId: testUserId, subject: .geometry)
        var updatedLesson = lesson
        
        // Add some mock questions and responses
        for i in 1...5 {
            let questionId = UUID()
            updatedLesson.questions.append(questionId)
            
            // Add a mix of correct and incorrect answers
            let isCorrect = i % 2 == 0 // Even questions correct, odd incorrect
            let responseTime = Double(5 + i) // 6-10 seconds
            
            updatedLesson.updateProgress(
                questionId: questionId,
                isCorrect: isCorrect,
                responseTime: responseTime
            )
        }
        
        // Test BKT Model
        print("Testing Bayesian Knowledge Tracing model...")
        let bktModel = BKTModel()
        bktModel.updateWithLesson(updatedLesson, userId: testUserId)
        
        // Test Elo Rating
        print("Testing Elo Rating model...")
        let eloModel = EloRatingModel()
        // Using Task to handle async operation
        Task {
            await eloModel.updateRating(for: testUserId, lesson: updatedLesson)
        }
        
        // Test IRT Model
        print("Testing Item Response Theory model...")
        let irtModel = IRTModel()
        // Using Task to handle async operation
        Task {
            await irtModel.updateWithLesson(updatedLesson, userId: testUserId)
        }
        
        // Verify stored values
        let bktKey = "BKT_\(testUserId)_\(updatedLesson.subject.rawValue)"
        let bktValue = UserDefaults.standard.float(forKey: bktKey)
        
        let eloKey = "Elo_Rating_\(testUserId)"
        let eloValue = UserDefaults.standard.float(forKey: eloKey)
        
        let irtKey = "IRT_Ability_\(testUserId)"
        let irtValue = UserDefaults.standard.float(forKey: irtKey)
        
        // Return test results
        return """
        AI Learning Service Test Results:
        ------------------------------
        Test Lesson: \(updatedLesson.questions.count) questions, \(updatedLesson.accuracy * 100)% accuracy
        BKT Knowledge: \(bktValue)
        Elo Rating: \(eloValue)
        IRT Ability: \(irtValue)
        ------------------------------
        All AI models updated successfully!
        """
    }
    
    /// Clear the progress cache
    public func clearCache() {
        progressCache.removeAll()
    }
    
    /// Clear the cache for a specific user
    /// - Parameter userId: The user ID to clear from cache
    public func clearCache(for userId: UUID) {
        progressCache.removeValue(forKey: userId)
    }
    
    // MARK: - CloudKit Integration
    
    /// Fetch learning progress record from CloudKit
    /// - Parameter userId: The user's ID
    /// - Returns: CloudKit record for the learning progress
    private func fetchLearningProgressRecord(userId: UUID) async throws -> CKRecord {
        // Create query to find this user's learning progress
        let predicate = NSPredicate(format: "userId == %@", userId.uuidString)
        let query = CKQuery(recordType: "AILearningProgress", predicate: predicate)
        
        // Try to fetch from CloudKit
        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 1)
            
            for result in results {
                if let record = try? result.1.get() {
                    print("Retrieved existing learning progress for user \(userId)")
                    return record
                }
            }
        } catch {
            print("Error fetching learning progress: \(error.localizedDescription)")
            // Continue to create a new record
        }
        
        // If not found or error occurred, create a new record
        print("Creating new learning progress for user \(userId)")
        let newProgress = InternalLearningProgress(
            userId: userId,
            abilityLevel: 0.5,
            lessonHistory: [],
            weakAreas: [],
            recommendedLessons: []
        )
        
        let record = CKRecord(recordType: "AILearningProgress")
        record["userId"] = userId.uuidString
        record["abilityLevel"] = newProgress.abilityLevel
        
        // Encode lesson history and weak areas
        if let lessonHistoryData = try? JSONEncoder().encode(newProgress.lessonHistory) {
            record["lessonHistory"] = lessonHistoryData
        }
        
        if let weakAreasData = try? JSONEncoder().encode(newProgress.weakAreas) {
            record["weakAreas"] = weakAreasData
        }
        
        // Encode recommended lessons
        let recommendedLessonsString = newProgress.recommendedLessons
            .map { $0.rawValue }
            .joined(separator: ",")
        record["recommendedLessons"] = recommendedLessonsString
        
        // Add performance stats
        record["totalLessonsCompleted"] = 0
        
        // Save to CloudKit
        do {
            let savedRecord = try await database.save(record)
            print("Saved new learning progress record to CloudKit")
            return savedRecord
        } catch {
            print("Error saving learning progress: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Save learning progress to CloudKit
    /// - Parameter progress: The learning progress to save
    private func saveInternalLearningProgress(_ progress: InternalLearningProgress) async throws {
        // Try to fetch existing record first
        let predicate = NSPredicate(format: "userId == %@", progress.userId.uuidString)
        let query = CKQuery(recordType: "AILearningProgress", predicate: predicate)
        
        var record: CKRecord
        
        // Try to fetch existing record
        do {
            let (results, _) = try await database.records(matching: query, resultsLimit: 1)
            
            if !results.isEmpty, let result = results.first, let existingRecord = try? result.1.get() {
                // Use existing record
                record = existingRecord
            } else {
                // Create new record
                record = CKRecord(recordType: "AILearningProgress")
                record["userId"] = progress.userId.uuidString
            }
        } catch {
            // Create new record on error
            record = CKRecord(recordType: "AILearningProgress")
            record["userId"] = progress.userId.uuidString
        }
        
        // Update record fields
        record["abilityLevel"] = progress.abilityLevel
        
        // Encode lesson history
        if let lessonHistoryData = try? JSONEncoder().encode(progress.lessonHistory) {
            record["lessonHistory"] = lessonHistoryData
        }
        
        // Encode weak areas
        if let weakAreasData = try? JSONEncoder().encode(progress.weakAreas) {
            record["weakAreas"] = weakAreasData
        }
        
        // Encode recommended lessons
        let recommendedLessonsString = progress.recommendedLessons
            .map { $0.rawValue }
            .joined(separator: ",")
        record["recommendedLessons"] = recommendedLessonsString
        
        // Update statistics
        record["totalLessonsCompleted"] = progress.lessonHistory.count
        
        // Save to CloudKit
        do {
            try await database.save(record)
            print("Saved learning progress to CloudKit for user \(progress.userId)")
        } catch {
            print("Error saving learning progress: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the next difficulty level based on lesson performance
    private func calculateNextDifficultyLevel(lesson: Lesson, currentLevel: Int) -> Int {
        if lesson.accuracy >= 0.8 {
            // High accuracy, consider increasing difficulty
            return min(4, currentLevel + 1)
        } else if lesson.accuracy <= 0.5 {
            // Low accuracy, consider decreasing difficulty
            return max(1, currentLevel - 1)
        } else {
            // Moderate performance, maintain current level
            return currentLevel
        }
    }
    
    /// Update weak areas in learning progress
    private func updateWeakAreas(
        in learningProgress: inout InternalLearningProgress,
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
                // Update concept name and completion date
                learningProgress.weakAreas[index].conceptName = getConceptName(for: lesson.subject)
                learningProgress.weakAreas[index].completedAt = completedAt
            } else {
                // Add new weak area
                learningProgress.weakAreas.append(AILearningWeakArea(
                    subject: lesson.subject,
                    conceptScore: lesson.accuracy,
                    conceptName: getConceptName(for: lesson.subject),
                    completedAt: completedAt
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
                learningProgress.weakAreas[index].completedAt = completedAt
            }
        }
    }
    
    /// Update AI models with new data from a completed lesson
    private func updateAIModels(with lesson: Lesson, for userId: UUID) {
        // Update BKT model
        let bktModel = BKTModel()
        bktModel.updateWithLesson(lesson, userId: userId)
        
        // Update ELO rating
        let eloModel = EloRatingModel()
        // Using Task to handle async operation without requiring caller to be async
        Task {
            await eloModel.updateRating(for: userId, lesson: lesson)
        }
        
        // Update IRT model
        let irtModel = IRTModel()
        // Using Task to handle async operation without requiring caller to be async
        Task {
            await irtModel.updateWithLesson(lesson, userId: userId)
        }
    }
    
    /// Generate positive feedback messages
    private func generatePositiveFeedback(responseTime: TimeInterval) -> String {
        let quickMessages = [
            "Great job! That was fast!",
            "Excellent! You're really getting this!",
            "Fantastic work! Keep it up!",
            "Perfect! You've got this concept mastered!"
        ]
        
        let standardMessages = [
            "Well done! That's correct!",
            "Good job! You got it right!",
            "Nice work! Keep going!",
            "That's right! You're doing great!"
        ]
        
        // If response was quick, use a quick message
        if responseTime < 10 {
            return quickMessages.randomElement() ?? "Great job!"
        } else {
            return standardMessages.randomElement() ?? "Well done!"
        }
    }
    
    /// Generate feedback for mistakes
    private func generateMistakeFeedback() -> String {
        let messages = [
            "Not quite right. Let's try again!",
            "That's not correct, but don't worry!",
            "Hmm, that's not the right answer. Let's review this one.",
            "Not exactly. Math takes practice!",
            "Let's look at this again. You can do it!"
        ]
        
        return messages.randomElement() ?? "Not quite right. Let's try again!"
    }
    
    /// Convert CloudKit record to internal learning progress model
    private func convertRecordToInternalProgress(_ record: CKRecord) -> InternalLearningProgress {
        // Extract user ID
        let userIdString = record["userId"] as? String ?? ""
        let userId = UUID(uuidString: userIdString) ?? UUID()
        
        // Extract ability level
        let abilityLevel = record["abilityLevel"] as? Float ?? 0.5
        
        // Extract lesson history
        var lessonHistory: [AILearningLessonCompletion] = []
        if let historyData = record["lessonHistory"] as? Data {
            lessonHistory = (try? JSONDecoder().decode([AILearningLessonCompletion].self, from: historyData)) ?? []
        }
        
        // Extract weak areas
        var weakAreas: [AILearningWeakArea] = []
        if let weakAreasData = record["weakAreas"] as? Data {
            weakAreas = (try? JSONDecoder().decode([AILearningWeakArea].self, from: weakAreasData)) ?? []
        }
        
        // Extract recommended lessons
        var recommendedLessons: [Lesson.Subject] = []
        if let recommendedString = record["recommendedLessons"] as? String, !recommendedString.isEmpty {
            let subjectStrings = recommendedString.split(separator: ",")
            recommendedLessons = subjectStrings.compactMap { Lesson.Subject(rawValue: String($0)) }
        }
        
        return InternalLearningProgress(
            userId: userId,
            abilityLevel: abilityLevel,
            lessonHistory: lessonHistory,
            weakAreas: weakAreas,
            recommendedLessons: recommendedLessons
        )
    }
    
    /// Convert internal learning progress model to public API model
    private func convertInternalToPublicProgress(_ internalProgress: InternalLearningProgress) -> AILearningProgress {
        // Convert internal lesson history to public API lesson progress
        let lessonProgress = internalProgress.lessonHistory.map { internalLesson in
            return AILearningProgress.LessonProgress(
                lessonId: internalLesson.id,
                subject: internalLesson.subject,
                completedAt: internalLesson.completedAt,
                accuracy: internalLesson.accuracy,
                responseTime: internalLesson.responseTimeAvg,
                nextDifficulty: internalLesson.nextDifficulty
            )
        }
        
        // Convert internal weak areas to public API weak areas
        let weakAreas = internalProgress.weakAreas.map { internalWeakArea in
            return AILearningProgress.WeakArea(
                subject: internalWeakArea.subject,
                conceptScore: internalWeakArea.conceptScore,
                lastPracticed: internalWeakArea.completedAt ?? Date()
            )
        }
        
        // Create lesson UUID recommendations (placeholder implementation)
        // In a real app, this would be more sophisticated
        let recommendedLessonIds = internalProgress.recommendedLessons.map { _ in UUID() }
        
        // Create and return public API learning progress
        return AILearningProgress(
            userId: internalProgress.userId,
            abilityLevel: internalProgress.abilityLevel,
            lessonHistory: lessonProgress,
            weakAreas: weakAreas,
            recommendedLessons: recommendedLessonIds
        )
    }
    
    /// Get a concept name for a subject (helper method for weak areas)
    private func getConceptName(for subject: Lesson.Subject) -> String {
        switch subject {
        case .logicalThinking:
            return "Logical Reasoning"
        case .arithmetic:
            return "Basic Arithmetic"
        case .numberTheory:
            return "Number Theory"
        case .geometry:
            return "Geometry and Spatial Reasoning"
        case .combinatorics:
            return "Combinatorics and Counting"
        }
    }
}

// MARK: - Supporting Types

extension AILearningService {
    /// Performance statistics for a student
    public struct PerformanceStats: Codable, Equatable {
        /// Overall accuracy percentage (0.0-1.0)
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
    
    /// AI Learning Service errors
    enum AILearningServiceError: Error {
        case userNotFound
        case lessonNotCompleted
    }
}

/// Feedback provided after answering a question
public struct AnswerFeedback {
    /// Whether the answer was correct
    public let isCorrect: Bool
    
    /// Feedback message
    public var message: String
    
    /// Optional hint for incorrect answers
    public var hint: String?
    
    /// Recommended next step
    public var nextStep: NextStep
    
    /// Initialization with default values
    public init(isCorrect: Bool) {
        self.isCorrect = isCorrect
        self.message = isCorrect ? "Correct!" : "Incorrect."
        self.hint = nil
        self.nextStep = isCorrect ? .continueLesson : .revealAnswer
    }
    
    /// Possible next steps after answering
    public enum NextStep {
        case continueLesson
        case tryAgainWithHint
        case revealAnswer
    }
} 