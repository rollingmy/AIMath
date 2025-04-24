import Foundation

/// Test script for validating AI Models
struct AIModelTester {
    /// Run all tests for AI models
    static func runTests() {
        print("Testing AI Models for TIMO Math Adaptive Learning...")
        
        // Test Elo Rating Model
        testEloRatingModel()
        
        // Test BKT Model
        testBKTModel()
        
        // Test IRT Model
        testIRTModel()
        
        // Test Adaptive Difficulty Engine
        testAdaptiveDifficultyEngine()
        
        print("All AI Model tests completed!")
    }
    
    /// Test the Elo Rating Model
    static func testEloRatingModel() {
        print("\n=== Testing Elo Rating Model ===")
        
        let eloModel = EloRatingModel()
        
        // Test case 1: Student with average rating answers correctly quickly
        let newRating1 = eloModel.calculateNewStudentRating(
            currentRating: 1200,
            questionDifficulty: 1200,
            isCorrect: true,
            responseTime: 15.0
        )
        print("Student rating after correct answer: \(newRating1)")
        
        // Test case 2: Student with average rating answers incorrectly
        let newRating2 = eloModel.calculateNewStudentRating(
            currentRating: 1200,
            questionDifficulty: 1200,
            isCorrect: false,
            responseTime: 30.0
        )
        print("Student rating after incorrect answer: \(newRating2)")
        
        // Test case 3: High-rated student answers easy question correctly
        let newRating3 = eloModel.calculateNewStudentRating(
            currentRating: 1500,
            questionDifficulty: 1000,
            isCorrect: true,
            responseTime: 10.0
        )
        print("High-rated student after correct answer to easy question: \(newRating3)")
        
        // Test difficulty level conversion
        let easyLevel = eloModel.convertEloToDifficultyLevel(1050)
        let mediumLevel = eloModel.convertEloToDifficultyLevel(1200)
        let hardLevel = eloModel.convertEloToDifficultyLevel(1400)
        let olympiadLevel = eloModel.convertEloToDifficultyLevel(1600)
        
        print("Elo 1050 -> Difficulty \(easyLevel)")
        print("Elo 1200 -> Difficulty \(mediumLevel)")
        print("Elo 1400 -> Difficulty \(hardLevel)")
        print("Elo 1600 -> Difficulty \(olympiadLevel)")
    }
    
    /// Test the Bayesian Knowledge Tracing Model
    static func testBKTModel() {
        print("\n=== Testing Bayesian Knowledge Tracing Model ===")
        
        let bktModel = BKTModel()
        
        // Test case 1: Student with low prior knowledge answers correctly
        let newKnowledge1 = bktModel.updateKnowledge(priorKnowledge: 0.3, isCorrect: true)
        print("Knowledge after correct answer (low prior): \(newKnowledge1)")
        
        // Test case 2: Student with medium prior knowledge answers incorrectly
        let newKnowledge2 = bktModel.updateKnowledge(priorKnowledge: 0.5, isCorrect: false)
        print("Knowledge after incorrect answer (medium prior): \(newKnowledge2)")
        
        // Test case 3: Student with high prior knowledge answers correctly
        let newKnowledge3 = bktModel.updateKnowledge(priorKnowledge: 0.8, isCorrect: true)
        print("Knowledge after correct answer (high prior): \(newKnowledge3)")
        
        // Test concept mastery determination
        let notMastered = bktModel.isConceptMastered(knowledge: 0.7)
        let mastered = bktModel.isConceptMastered(knowledge: 0.9)
        
        print("Knowledge 0.7 mastered? \(notMastered)")
        print("Knowledge 0.9 mastered? \(mastered)")
    }
    
    /// Test the Item Response Theory Model
    static func testIRTModel() {
        print("\n=== Testing Item Response Theory Model ===")
        
        let irtModel = IRTModel()
        
        // Create test parameters
        let easyParams = IRTModel.Parameters(discrimination: 1.0, difficulty: -1.0, guessing: 0.25)
        let mediumParams = IRTModel.Parameters(discrimination: 1.0, difficulty: 0.0, guessing: 0.25)
        let hardParams = IRTModel.Parameters(discrimination: 1.0, difficulty: 1.0, guessing: 0.25)
        
        // Test probability calculations for different student abilities
        let lowAbility = -1.0
        let mediumAbility = 0.0
        let highAbility = 1.0
        
        // Low ability student
        print("Low ability student (-1.0):")
        print("  Probability on easy question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(lowAbility), parameters: easyParams))")
        print("  Probability on medium question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(lowAbility), parameters: mediumParams))")
        print("  Probability on hard question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(lowAbility), parameters: hardParams))")
        
        // Medium ability student
        print("Medium ability student (0.0):")
        print("  Probability on easy question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(mediumAbility), parameters: easyParams))")
        print("  Probability on medium question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(mediumAbility), parameters: mediumParams))")
        print("  Probability on hard question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(mediumAbility), parameters: hardParams))")
        
        // High ability student
        print("High ability student (1.0):")
        print("  Probability on easy question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(highAbility), parameters: easyParams))")
        print("  Probability on medium question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(highAbility), parameters: mediumParams))")
        print("  Probability on hard question: \(irtModel.probabilityOfCorrectAnswer(ability: Float(highAbility), parameters: hardParams))")
        
        // Test ability estimation
        let updatedAbility = irtModel.estimateAbility(
            currentAbility: 0.0,
            questionParameters: mediumParams,
            isCorrect: true
        )
        print("Updated ability after correct answer: \(updatedAbility)")
    }
    
    /// Test the Adaptive Difficulty Engine
    static func testAdaptiveDifficultyEngine() {
        print("\n=== Testing Adaptive Difficulty Engine ===")
        
        let engine = AdaptiveDifficultyEngine.shared
        
        // Create a sample learning progress
        let userId = UUID()
        var learningProgress = AILearningProgress(userId: userId)
        
        // Add some lesson history
        learningProgress.lessonHistory = [
            AILearningProgress.LessonProgress(
                lessonId: UUID(),
                subject: .arithmetic,
                completedAt: Date(),
                accuracy: 0.8,
                responseTime: 25.0,
                nextDifficulty: 2
            )
        ]
        
        // Add a weak area
        learningProgress.weakAreas = [
            AILearningProgress.WeakArea(
                subject: .geometry,
                conceptScore: 0.4,
                lastPracticed: Date().addingTimeInterval(-86400) // 1 day ago
            )
        ]
        
        // Test difficulty calculation for high accuracy
        let highAccuracyLesson = createTestLesson(userId: userId, accuracy: 0.95, responseTime: 20.0)
        let highAccuracyDifficulty = engine.calculateDifficultyAfterLesson(
            learningProgress: learningProgress,
            completedLesson: highAccuracyLesson
        )
        print("Next difficulty after high accuracy (0.95): \(highAccuracyDifficulty)")
        
        // Test difficulty calculation for low accuracy
        let lowAccuracyLesson = createTestLesson(userId: userId, accuracy: 0.3, responseTime: 40.0)
        let lowAccuracyDifficulty = engine.calculateDifficultyAfterLesson(
            learningProgress: learningProgress,
            completedLesson: lowAccuracyLesson
        )
        print("Next difficulty after low accuracy (0.3): \(lowAccuracyDifficulty)")
        
        // Test difficulty calculation for moderate accuracy
        let moderateAccuracyLesson = createTestLesson(userId: userId, accuracy: 0.6, responseTime: 30.0)
        let moderateAccuracyDifficulty = engine.calculateDifficultyAfterLesson(
            learningProgress: learningProgress,
            completedLesson: moderateAccuracyLesson
        )
        print("Next difficulty after moderate accuracy (0.6): \(moderateAccuracyDifficulty)")
    }
    
    /// Create a test lesson with specified parameters
    static func createTestLesson(userId: UUID, accuracy: Float, responseTime: TimeInterval) -> Lesson {
        var lesson = Lesson(userId: userId, subject: .arithmetic)
        lesson.accuracy = accuracy
        lesson.responseTime = responseTime
        lesson.status = .completed
        lesson.completedAt = Date()
        return lesson
    }
}

// Comment out or remove the top-level expression
// AIModelTester.runTests() 