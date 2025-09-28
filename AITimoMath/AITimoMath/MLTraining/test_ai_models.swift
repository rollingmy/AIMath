import Foundation

/// Test script for validating AI Models
struct AIModelTester {
    /// Run all tests for AI models
    static func runTests() {
        print("\n=== Running AI Model Tests ===\n")
        testEloRatingModel()
        testBKTModel()
        testIRTModel()
        testAdaptiveDifficultyEngine()
        print("\n=== All AI Model Tests Completed ===\n")
    }
    
    /// Test the Elo Rating Model
    static func testEloRatingModel() {
        print("Testing Elo Rating Model...")
        
        let model = EloRatingModel()
        
        // Test calculating new ratings after correct answer
        let studentRating1 = model.calculateNewStudentRating(
            currentRating: 1200, 
            questionDifficulty: 1000, 
            isCorrect: true,
            responseTime: 10.0
        )
        print("  Student rating after correct answer (1200 vs 1000): \(studentRating1)")
        
        let questionRating1 = model.calculateNewQuestionDifficulty(
            currentDifficulty: 1000,
            studentRating: 1200,
            isCorrect: true,
            responseTime: 10.0
        )
        print("  Question rating after correct answer (1000 vs 1200): \(questionRating1)")
        
        // Test calculating new ratings after incorrect answer
        let studentRating2 = model.calculateNewStudentRating(
            currentRating: 1200, 
            questionDifficulty: 1000, 
            isCorrect: false,
            responseTime: 20.0
        )
        print("  Student rating after incorrect answer (1200 vs 1000): \(studentRating2)")
        
        let questionRating2 = model.calculateNewQuestionDifficulty(
            currentDifficulty: 1000,
            studentRating: 1200,
            isCorrect: false,
            responseTime: 20.0
        )
        print("  Question rating after incorrect answer (1000 vs 1200): \(questionRating2)")
        
        // Test converting Elo rating to difficulty level
        let difficultyLevel1 = model.convertEloToDifficultyLevel(1000)
        let difficultyLevel2 = model.convertEloToDifficultyLevel(1200)
        let difficultyLevel3 = model.convertEloToDifficultyLevel(1400)
        
        print("  Difficulty level (rating 1000): \(difficultyLevel1)")
        print("  Difficulty level (rating 1200): \(difficultyLevel2)")
        print("  Difficulty level (rating 1400): \(difficultyLevel3)")
        
        print("Elo Rating Model test completed\n")
    }
    
    /// Test the Bayesian Knowledge Tracing Model
    static func testBKTModel() {
        print("Testing Bayesian Knowledge Tracing Model...")
        
        let model = BKTModel()
        
        // Test updating knowledge based on responses
        let knowledgeAfterCorrect = model.updateKnowledge(priorKnowledge: 0.5, isCorrect: true)
        let knowledgeAfterIncorrect = model.updateKnowledge(priorKnowledge: 0.5, isCorrect: false)
        
        print("  Knowledge after correct answer (from 0.5): \(knowledgeAfterCorrect)")
        print("  Knowledge after incorrect answer (from 0.5): \(knowledgeAfterIncorrect)")
        
        // Test knowledge gain for a sequence of responses
        var knowledge: Float = 0.4 // Initial knowledge
        print("  Initial knowledge state: \(knowledge)")
        
        let responses = [true, true, false, true, true]
        for (index, isCorrect) in responses.enumerated() {
            knowledge = model.updateKnowledge(priorKnowledge: knowledge, isCorrect: isCorrect)
            print("  Knowledge after response \(index+1) (\(isCorrect ? "correct" : "incorrect")): \(knowledge)")
        }
        
        // Test concept mastery determination
        let conceptMastered = model.isConceptMastered(knowledge: knowledge)
        print("  Is concept mastered with knowledge \(knowledge)? \(conceptMastered)")
        
        print("Bayesian Knowledge Tracing Model test completed\n")
    }
    
    /// Test the Item Response Theory Model
    static func testIRTModel() {
        print("Testing Item Response Theory Model...")
        
        let model = IRTModel()
        
        // Test calculating probability of correct answer
        let params1 = IRTModel.Parameters(discrimination: 1.0, difficulty: 0.0, guessing: 0.25)
        let params2 = IRTModel.Parameters(discrimination: 1.0, difficulty: 1.0, guessing: 0.25)
        let params3 = IRTModel.Parameters(discrimination: 1.0, difficulty: 0.0, guessing: 0.25)
        
        let probability1 = model.probabilityOfCorrectAnswer(ability: 1.0, parameters: params1)
        let probability2 = model.probabilityOfCorrectAnswer(ability: 0.0, parameters: params2)
        let probability3 = model.probabilityOfCorrectAnswer(ability: 0.0, parameters: params3)
        
        print("  Probability (ability 1.0, difficulty 0.0): \(probability1)")
        print("  Probability (ability 0.0, difficulty 1.0): \(probability2)")
        print("  Probability (ability 0.0, difficulty 0.0): \(probability3)")
        
        // Test estimating ability after responses
        var ability: Float = 0.0
        let questionDifficulties: [Float] = [0.0, 0.5, -0.5, 1.0, -1.0]
        let responses = [true, true, true, false, true]
        
        print("  Initial ability: \(ability)")
        
        for i in 0..<questionDifficulties.count {
            let params = IRTModel.Parameters(discrimination: 1.0, difficulty: questionDifficulties[i], guessing: 0.25)
            ability = model.estimateAbility(
                currentAbility: ability,
                questionParameters: params,
                isCorrect: responses[i]
            )
            
            print("  Ability after \(responses[i] ? "correct" : "incorrect") answer to question with difficulty \(questionDifficulties[i]): \(ability)")
        }
        
        print("Item Response Theory Model test completed\n")
    }
    
    /// Test the Adaptive Difficulty Engine
    static func testAdaptiveDifficultyEngine() {
        print("Testing Adaptive Difficulty Engine...")
        
        let engine = AdaptiveDifficultyEngine.shared
        
        // Create a test learning progress
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
        
        // Create a test lesson
        let lesson = createTestLesson(userId: userId)
        
        // Test difficulty calculation
        let nextDifficulty = engine.calculateDifficultyAfterLesson(
            learningProgress: learningProgress,
            completedLesson: lesson
        )
        
        print("  Next difficulty after performance: \(nextDifficulty)")
        
        print("Adaptive Difficulty Engine test completed\n")
    }
    
    // Helper function to create a test lesson
    private static func createTestLesson(userId: UUID) -> Lesson {
        let questionCount = 10
        let subject: Lesson.Subject = .arithmetic
        let accuracy: Float = 0.7
        
        // Create question responses
        var responses = [Lesson.QuestionResponse]()
        let correctCount = Int(Float(questionCount) * accuracy)
        
        for i in 0..<questionCount {
            let isCorrect = i < correctCount
            let response = Lesson.QuestionResponse(
                questionId: UUID(),
                isCorrect: isCorrect,
                responseTime: Double.random(in: 15...45),
                answeredAt: Date(),
                selectedAnswer: isCorrect ? "A" : "B"
            )
            responses.append(response)
        }
        
        // Create and return a lesson
        return Lesson(
            id: UUID(),
            userId: userId,
            subject: subject,
            difficulty: 2,
            questions: [],
            responses: responses,
            accuracy: accuracy,
            responseTime: 25.0,
            startedAt: Date().addingTimeInterval(-600),
            status: .completed
        )
    }
}

/// Test runner for AI models
public class MLTestRunner {
    /// Run all AI model tests (legacy method)
    public static func runAllTests() {
        AIModelTester.runTests()
    }
    
    /// Run comprehensive accuracy tests
    public static func runAccuracyTests() {
        print("🧪 Running Comprehensive AI Model Accuracy Tests...")
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        // Generate analysis report
        let analysisReport = TestResultsAnalyzer.generateReport(results)
        print(analysisReport)
    }
    
    /// Run all tests including accuracy validation
    public static func runCompleteTestSuite() {
        print("🚀 Running Complete AI Model Test Suite...")
        print(String(repeating: "=", count: 60))
        
        // Run basic functionality tests
        print("\n1. Basic Functionality Tests")
        print(String(repeating: "-", count: 30))
        AIModelTester.runTests()
        
        // Run comprehensive accuracy tests
        print("\n2. Comprehensive Accuracy Tests")
        print(String(repeating: "-", count: 30))
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        // Generate and display analysis report
        print("\n3. Analysis Report")
        print(String(repeating: "-", count: 30))
        let analysisReport = TestResultsAnalyzer.generateReport(results)
        print(analysisReport)
        
        print("\n🏁 Complete test suite finished!")
    }
    
    /// Run tests with custom configuration
    public static func runCustomTests(
        accuracyThreshold: Float = 0.85,
        testIterations: Int = 1000
    ) {
        print("⚙️ Running Custom AI Model Tests...")
        print("Accuracy Threshold: \(String(format: "%.2f%%", accuracyThreshold * 100))")
        print("Test Iterations: \(testIterations)")
        
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        // Filter results based on custom threshold
        let filteredResults = results.filter { $0.value.accuracy >= accuracyThreshold }
        
        print("\nResults meeting custom threshold:")
        for (modelName, result) in filteredResults {
            print("✅ \(modelName): \(String(format: "%.2f%%", result.accuracy * 100))")
        }
        
        let analysisReport = TestResultsAnalyzer.generateReport(results)
        print(analysisReport)
    }
} 