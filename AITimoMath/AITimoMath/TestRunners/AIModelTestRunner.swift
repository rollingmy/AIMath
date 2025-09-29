import Foundation
import SwiftUI

/// Test runner for AI Models
class AIModelTestRunner {
    /// Flag to store test results
    private(set) var testResults: [String] = []
    
    /// Run all tests for AI models
    func runTests() -> [String] {
        testResults.append("Testing AI Models for TIMO Math Adaptive Learning...")
        
        // Test Elo Rating Model
        testEloRatingModel()
        
        // Test BKT Model
        testBKTModel()
        
        // Test IRT Model
        testIRTModel()
        
        // Test CoreML Service
        testCoreMLService()
        
        // Test Adaptive Difficulty Engine
        testAdaptiveDifficultyEngine()
        
        testResults.append("All AI Model tests completed!")
        return testResults
    }
    
    /// Run comprehensive accuracy tests for all AI models
    func runAccuracyTests() -> [String] {
        testResults.append("🧪 Running Comprehensive AI Model Accuracy Tests...")
        testResults.append(String(repeating: "=", count: 60))
        
        let comprehensiveTests = ComprehensiveAITests()
        let accuracyResults = comprehensiveTests.runAllAccuracyTests()
        
        for (modelName, result) in accuracyResults {
            let status = result.passed ? "✅ PASSED" : "❌ FAILED"
            testResults.append("\(modelName): \(status)")
            testResults.append("  Accuracy: \(String(format: "%.2f%%", result.accuracy * 100))")
            testResults.append("  Test Cases: \(result.testCases)")
            testResults.append("  Details: \(result.details)")
            testResults.append("")
        }
        
        // Calculate overall results
        let passedModels = accuracyResults.values.filter { $0.passed }.count
        let totalModels = accuracyResults.count
        let overallSuccessRate = Float(passedModels) / Float(totalModels)
        
        testResults.append("📊 Overall Accuracy Test Results:")
        testResults.append("  Models Passed: \(passedModels)/\(totalModels)")
        testResults.append("  Success Rate: \(String(format: "%.2f%%", overallSuccessRate * 100))")
        
        if overallSuccessRate >= 0.8 {
            testResults.append("🎉 AI Models meet accuracy requirements!")
        } else {
            testResults.append("⚠️ Some AI models need improvement before deployment.")
        }
        
        testResults.append("")
        testResults.append("✅ Comprehensive accuracy testing completed!")
        
        return testResults
    }
    
    /// Run usability tests
    func runUsabilityTests() async -> [String] {
        testResults.append("🧪 Running Automated Usability Tests...")
        testResults.append("")
        
        let runner = UsabilityTestRunner()
        let usabilityResults = await runner.runUsabilityTests()
        
        testResults.append(contentsOf: usabilityResults)
        testResults.append("")
        testResults.append("✅ Automated Usability Tests completed!")
        
        return testResults
    }
    
    /// Run both basic and accuracy tests
    func runAllTests() -> [String] {
        testResults.append("🚀 Starting Complete AI Model Testing Suite...")
        testResults.append("")
        
        // Run basic functionality tests
        _ = runTests()
        
        testResults.append("")
        testResults.append("")
        
        // Run comprehensive accuracy tests
        _ = runAccuracyTests()
        
        testResults.append("")
        testResults.append("🏁 Complete AI Model Testing Suite finished!")
        
        return testResults
    }
    
    /// Static method to run all tests
    static func runAllTests() {
        let testRunner = AIModelTestRunner()
        let results = testRunner.runAllTests()
        
        // Print results to console
        for result in results {
            print(result)
        }
    }
    
    /// Static method to run only accuracy tests
    static func runAccuracyTests() {
        let testRunner = AIModelTestRunner()
        let results = testRunner.runAccuracyTests()
        
        // Print results to console
        for result in results {
            print(result)
        }
    }
    
    /// Static method to run only basic functionality tests
    static func runBasicTests() {
        let testRunner = AIModelTestRunner()
        let results = testRunner.runTests()
        
        // Print results to console
        for result in results {
            print(result)
        }
    }
    
    /// Test the Elo Rating Model
    private func testEloRatingModel() {
        testResults.append("\n=== Testing Elo Rating Model ===")
        
        let eloModel = EloRatingModel()
        
        // Test case 1: Student with average rating answers correctly quickly
        let newRating1 = eloModel.calculateNewStudentRating(
            currentRating: 1200,
            questionDifficulty: 1200,
            isCorrect: true,
            responseTime: 15.0
        )
        testResults.append("Student rating after correct answer: \(newRating1)")
        
        // Test case 2: Student with average rating answers incorrectly
        let newRating2 = eloModel.calculateNewStudentRating(
            currentRating: 1200,
            questionDifficulty: 1200,
            isCorrect: false,
            responseTime: 30.0
        )
        testResults.append("Student rating after incorrect answer: \(newRating2)")
        
        // Test case 3: High-rated student answers easy question correctly
        let newRating3 = eloModel.calculateNewStudentRating(
            currentRating: 1500,
            questionDifficulty: 1000,
            isCorrect: true,
            responseTime: 10.0
        )
        testResults.append("High-rated student after correct answer to easy question: \(newRating3)")
        
        // Test difficulty level conversion
        let easyLevel = eloModel.convertEloToDifficultyLevel(1050)
        let mediumLevel = eloModel.convertEloToDifficultyLevel(1200)
        let hardLevel = eloModel.convertEloToDifficultyLevel(1400)
        let olympiadLevel = eloModel.convertEloToDifficultyLevel(1600)
        
        testResults.append("Elo 1050 -> Difficulty \(easyLevel)")
        testResults.append("Elo 1200 -> Difficulty \(mediumLevel)")
        testResults.append("Elo 1400 -> Difficulty \(hardLevel)")
        testResults.append("Elo 1600 -> Difficulty \(olympiadLevel)")
    }
    
    /// Test the Bayesian Knowledge Tracing Model
    private func testBKTModel() {
        testResults.append("\n=== Testing Bayesian Knowledge Tracing Model ===")
        
        let bktModel = BKTModel()
        
        // Test case 1: Student with low prior knowledge answers correctly
        let newKnowledge1 = bktModel.updateKnowledge(priorKnowledge: 0.3, isCorrect: true)
        testResults.append("Knowledge after correct answer (low prior): \(newKnowledge1)")
        
        // Test case 2: Student with medium prior knowledge answers incorrectly
        let newKnowledge2 = bktModel.updateKnowledge(priorKnowledge: 0.5, isCorrect: false)
        testResults.append("Knowledge after incorrect answer (medium prior): \(newKnowledge2)")
        
        // Test case 3: Student with high prior knowledge answers correctly
        let newKnowledge3 = bktModel.updateKnowledge(priorKnowledge: 0.8, isCorrect: true)
        testResults.append("Knowledge after correct answer (high prior): \(newKnowledge3)")
        
        // Test concept mastery determination
        let notMastered = bktModel.isConceptMastered(knowledge: 0.7)
        let mastered = bktModel.isConceptMastered(knowledge: 0.9)
        
        testResults.append("Knowledge 0.7 mastered? \(notMastered)")
        testResults.append("Knowledge 0.9 mastered? \(mastered)")
    }
    
    /// Test the Item Response Theory Model
    private func testIRTModel() {
        testResults.append("\n=== Testing Item Response Theory Model ===")
        
        let irtModel = IRTModel()
        
        // Create test parameters
        let easyParams = IRTModel.Parameters(discrimination: 1.0, difficulty: -1.0, guessing: 0.25)
        let mediumParams = IRTModel.Parameters(discrimination: 1.0, difficulty: 0.0, guessing: 0.25)
        let hardParams = IRTModel.Parameters(discrimination: 1.0, difficulty: 1.0, guessing: 0.25)
        
        // Test probability calculations for different student abilities
        let lowAbility: Float = -1.0
        let mediumAbility: Float = 0.0
        let highAbility: Float = 1.0
        
        // Low ability student
        testResults.append("Low ability student (-1.0):")
        testResults.append("  Probability on easy question: \(irtModel.probabilityOfCorrectAnswer(ability: lowAbility, parameters: easyParams))")
        testResults.append("  Probability on medium question: \(irtModel.probabilityOfCorrectAnswer(ability: lowAbility, parameters: mediumParams))")
        testResults.append("  Probability on hard question: \(irtModel.probabilityOfCorrectAnswer(ability: lowAbility, parameters: hardParams))")
        
        // Medium ability student
        testResults.append("Medium ability student (0.0):")
        testResults.append("  Probability on easy question: \(irtModel.probabilityOfCorrectAnswer(ability: mediumAbility, parameters: easyParams))")
        testResults.append("  Probability on medium question: \(irtModel.probabilityOfCorrectAnswer(ability: mediumAbility, parameters: mediumParams))")
        testResults.append("  Probability on hard question: \(irtModel.probabilityOfCorrectAnswer(ability: mediumAbility, parameters: hardParams))")
        
        // High ability student
        testResults.append("High ability student (1.0):")
        testResults.append("  Probability on easy question: \(irtModel.probabilityOfCorrectAnswer(ability: highAbility, parameters: easyParams))")
        testResults.append("  Probability on medium question: \(irtModel.probabilityOfCorrectAnswer(ability: highAbility, parameters: mediumParams))")
        testResults.append("  Probability on hard question: \(irtModel.probabilityOfCorrectAnswer(ability: highAbility, parameters: hardParams))")
        
        // Test ability estimation
        let updatedAbility = irtModel.estimateAbility(
            currentAbility: 0.0,
            questionParameters: mediumParams,
            isCorrect: true
        )
        testResults.append("Updated ability after correct answer: \(updatedAbility)")
    }
    
    /// Test the CoreML Service with our trained models
    private func testCoreMLService() {
        testResults.append("\n=== Testing CoreML Service ===")
        
        let coreMLService = CoreMLService.shared
        
        // Test question recommendation
        testResults.append("Testing question recommendation...")
        
        // Create a test student profile
        let studentProfile: [String: Any] = [
            "ability": 0.5,
            "weakSubjects": ["Geometry", "Number Theory"],
            "subject_pref_0": 0.7,
            "subject_pref_1": 0.8,
            "subject_pref_2": 0.4,
            "subject_pref_3": 0.3,
            "subject_pref_4": 0.6
        ]
        
        // Create some test questions
        let question1 = Question(
            id: UUID(),
            subject: .arithmetic,
            difficulty: 1,
            type: .multipleChoice,
            questionText: "Test arithmetic question",
            correctAnswer: "42"
        )
        let question2 = Question(
            id: UUID(),
            subject: .geometry,
            difficulty: 2,
            type: .multipleChoice,
            questionText: "Test geometry question",
            correctAnswer: "Circle"
        )
        let question3 = Question(
            id: UUID(),
            subject: .logicalThinking,
            difficulty: 3,
            type: .openEnded,
            questionText: "Test logical thinking question",
            correctAnswer: "Logic"
        )
        
        let availableQuestions = [question1, question2, question3]
        
        // Test question recommendation
        do {
            let recommendedQuestions = try coreMLService.recommendQuestions(
                studentProfile: studentProfile,
                availableQuestions: availableQuestions,
                count: 2
            )
            testResults.append("Recommended \(recommendedQuestions.count) questions")
        } catch {
            testResults.append("Error recommending questions: \(error.localizedDescription)")
        }
        
        // Test question difficulty prediction
        testResults.append("Testing difficulty prediction...")
        
        let questionFeatures: [String: Any] = [
            "difficultyLevel": 2,
            "irt_discrimination": 1.2,
            "irt_difficulty": 0.5,
            "irt_guessing": 0.25
        ]
        
        do {
            let difficulty = try coreMLService.predictQuestionDifficulty(
                studentAbility: 0.0,
                questionFeatures: questionFeatures
            )
            testResults.append("Predicted difficulty: \(difficulty)")
        } catch {
            testResults.append("Error predicting difficulty: \(error.localizedDescription)")
        }
    }
    
    /// Test the Adaptive Difficulty Engine
    private func testAdaptiveDifficultyEngine() {
        testResults.append("\n=== Testing Adaptive Difficulty Engine ===")
        
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
        testResults.append("Next difficulty after high accuracy (0.95): \(highAccuracyDifficulty)")
        
        // Test difficulty calculation for low accuracy
        let lowAccuracyLesson = createTestLesson(userId: userId, accuracy: 0.3, responseTime: 40.0)
        let lowAccuracyDifficulty = engine.calculateDifficultyAfterLesson(
            learningProgress: learningProgress,
            completedLesson: lowAccuracyLesson
        )
        testResults.append("Next difficulty after low accuracy (0.3): \(lowAccuracyDifficulty)")
        
        // Test difficulty calculation for moderate accuracy
        let moderateAccuracyLesson = createTestLesson(userId: userId, accuracy: 0.6, responseTime: 30.0)
        let moderateAccuracyDifficulty = engine.calculateDifficultyAfterLesson(
            learningProgress: learningProgress,
            completedLesson: moderateAccuracyLesson
        )
        testResults.append("Next difficulty after moderate accuracy (0.6): \(moderateAccuracyDifficulty)")
    }
    
    /// Create a test lesson with specified parameters
    private func createTestLesson(userId: UUID, accuracy: Float, responseTime: TimeInterval) -> Lesson {
        var lesson = Lesson(userId: userId, subject: .arithmetic)
        lesson.accuracy = accuracy
        lesson.responseTime = responseTime
        lesson.status = .completed
        lesson.completedAt = Date()
        return lesson
    }
}

/// View for testing AI models
struct AIModelTestView: View {
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    @State private var selectedTestType: TestType = .all
    
    enum TestType: String, CaseIterable {
        case basic = "Basic Tests"
        case accuracy = "Accuracy Tests"
        case all = "All Tests"
    }
    
    var body: some View {
        VStack {
            Text("AI Model Tests")
                .font(.title)
                .padding()
            
            // Test type selector
            Picker("Test Type", selection: $selectedTestType) {
                ForEach(TestType.allCases, id: \.self) { testType in
                    Text(testType.rawValue).tag(testType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Run tests button
            Button(action: {
                self.runTests()
            }) {
                HStack {
                    if isRunningTests {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isRunningTests ? "Running Tests..." : "Run \(selectedTestType.rawValue)")
                }
                .padding()
                .background(isRunningTests ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isRunningTests)
            .padding()
            
            // Test results
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal)
                            .padding(.vertical, 1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
        }
    }
    
    private func runTests() {
        self.isRunningTests = true
        self.testResults = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            let testRunner = AIModelTestRunner()
            let results: [String]
            
            switch selectedTestType {
            case .basic:
                results = testRunner.runTests()
            case .accuracy:
                results = testRunner.runAccuracyTests()
            case .all:
                results = testRunner.runAllTests()
            }
            
            DispatchQueue.main.async {
                self.testResults = results
                self.isRunningTests = false
            }
        }
    }
} 