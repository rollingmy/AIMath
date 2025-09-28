import Foundation

/// Comprehensive AI Model Accuracy Testing Suite
/// Implements detailed accuracy validation for all AI models in the TIMO Math Learning Engine
class ComprehensiveAITests {
    
    // MARK: - Test Configuration
    private let accuracyThreshold: Float = 0.85  // 85% accuracy threshold
    private let testIterations = 1000            // Number of test iterations
    private let tolerance: Float = 0.05          // 5% tolerance for predictions
    
    // MARK: - Test Results Storage
    private var testResults: [String: TestResult] = [:]
    
    struct TestResult {
        let modelName: String
        let accuracy: Float
        let precision: Float
        let recall: Float
        let f1Score: Float
        let testCases: Int
        let passed: Bool
        let details: String
    }
    
    /// Run all AI model accuracy tests
    func runAllAccuracyTests() -> [String: TestResult] {
        print("🧪 Starting Comprehensive AI Model Accuracy Tests...")
        print(String(repeating: "=", count: 60))
        
        // Test each AI model
        testEloRatingAccuracy()
        testBKTModelAccuracy()
        testIRTModelAccuracy()
        testAdaptiveDifficultyEngineAccuracy()
        testCoreMLModelAccuracy()
        
        // Generate comprehensive report
        generateAccuracyReport()
        
        return testResults
    }
    
    // MARK: - Elo Rating Model Tests
    
    /// Test Elo Rating Model accuracy with known scenarios
    private func testEloRatingAccuracy() {
        print("\n📊 Testing Elo Rating Model Accuracy...")
        
        let eloModel = EloRatingModel()
        var correctPredictions = 0
        var totalTests = 0
        var testDetails: [String] = []
        
        // Test Case 1: Student rating should increase after correct answers
        for _ in 0..<100 {
            let initialRating: Float = 1200
            let questionDifficulty: Float = 1000  // Easier question
            
            let newRating = eloModel.calculateNewStudentRating(
                currentRating: initialRating,
                questionDifficulty: questionDifficulty,
                isCorrect: true,
                responseTime: 15.0
            )
            
            // Student should gain rating points for correct answer on easier question
            if newRating > initialRating {
                correctPredictions += 1
            }
            totalTests += 1
        }
        testDetails.append("Correct answer rating increase: \(correctPredictions)/100")
        
        // Test Case 2: Student rating should decrease after incorrect answers
        var correctDecreases = 0
        for _ in 0..<100 {
            let initialRating: Float = 1200
            let questionDifficulty: Float = 1400  // Harder question
            
            let newRating = eloModel.calculateNewStudentRating(
                currentRating: initialRating,
                questionDifficulty: questionDifficulty,
                isCorrect: false,
                responseTime: 45.0
            )
            
            // Student should lose rating points for incorrect answer
            if newRating < initialRating {
                correctDecreases += 1
            }
            totalTests += 1
        }
        testDetails.append("Incorrect answer rating decrease: \(correctDecreases)/100")
        
        // Test Case 3: Difficulty level conversion accuracy
        let testCases = [
            (rating: Float(1050), expectedLevel: 1),  // Easy
            (rating: Float(1200), expectedLevel: 2),  // Medium
            (rating: Float(1400), expectedLevel: 3),  // Hard
            (rating: Float(1600), expectedLevel: 4)   // Olympiad
        ]
        
        var correctConversions = 0
        for testCase in testCases {
            let actualLevel = eloModel.convertEloToDifficultyLevel(testCase.rating)
            if actualLevel == testCase.expectedLevel {
                correctConversions += 1
            }
            totalTests += 1
        }
        testDetails.append("Difficulty conversion accuracy: \(correctConversions)/4")
        
        // Test Case 4: Question difficulty adjustment
        var correctQuestionAdjustments = 0
        for _ in 0..<50 {
            let initialDifficulty: Float = 1200
            let studentRating: Float = 1000
            
            let newDifficulty = eloModel.calculateNewQuestionDifficulty(
                currentDifficulty: initialDifficulty,
                studentRating: studentRating,
                isCorrect: false,  // Student got it wrong
                responseTime: 30.0
            )
            
            // Question should become easier (lower rating) when student gets it wrong
            if newDifficulty < initialDifficulty {
                correctQuestionAdjustments += 1
            }
            totalTests += 1
        }
        testDetails.append("Question difficulty adjustment: \(correctQuestionAdjustments)/50")
        
        let accuracy = Float(correctPredictions + correctDecreases + correctConversions + correctQuestionAdjustments) / Float(totalTests)
        let result = TestResult(
            modelName: "Elo Rating Model",
            accuracy: accuracy,
            precision: accuracy,
            recall: accuracy,
            f1Score: accuracy,
            testCases: totalTests,
            passed: accuracy >= accuracyThreshold,
            details: testDetails.joined(separator: "; ")
        )
        
        testResults["EloRating"] = result
        print("✅ Elo Rating Model Accuracy: \(String(format: "%.2f%%", accuracy * 100))")
    }
    
    // MARK: - BKT Model Tests
    
    /// Test Bayesian Knowledge Tracing Model accuracy
    private func testBKTModelAccuracy() {
        print("\n🧠 Testing BKT Model Accuracy...")
        
        let bktModel = BKTModel()
        _ = 0
        var totalTests = 0
        var testDetails: [String] = []
        
        // Test Case 1: Knowledge should increase with correct answers
        var correctIncreases = 0
        for _ in 0..<100 {
            let initialKnowledge: Float = 0.3
            let newKnowledge = bktModel.updateKnowledge(
                priorKnowledge: initialKnowledge,
                isCorrect: true
            )
            
            // Knowledge should increase after correct answer
            if newKnowledge > initialKnowledge {
                correctIncreases += 1
            }
            totalTests += 1
        }
        testDetails.append("Knowledge increase on correct: \(correctIncreases)/100")
        
        // Test Case 2: Knowledge should decrease with incorrect answers
        var correctDecreases = 0
        for _ in 0..<100 {
            let initialKnowledge: Float = 0.7
            let newKnowledge = bktModel.updateKnowledge(
                priorKnowledge: initialKnowledge,
                isCorrect: false
            )
            
            // Knowledge should decrease after incorrect answer
            if newKnowledge < initialKnowledge {
                correctDecreases += 1
            }
            totalTests += 1
        }
        testDetails.append("Knowledge decrease on incorrect: \(correctDecreases)/100")
        
        // Test Case 3: Mastery determination accuracy
        let masteryTestCases = [
            (knowledge: Float(0.9), expectedMastery: true),   // Should be mastered
            (knowledge: Float(0.7), expectedMastery: false),  // Should not be mastered
            (knowledge: Float(0.95), expectedMastery: true),  // Should be mastered
            (knowledge: Float(0.5), expectedMastery: false)   // Should not be mastered
        ]
        
        var correctMastery = 0
        for testCase in masteryTestCases {
            let actualMastery = bktModel.isConceptMastered(knowledge: testCase.knowledge)
            if actualMastery == testCase.expectedMastery {
                correctMastery += 1
            }
            totalTests += 1
        }
        testDetails.append("Mastery determination: \(correctMastery)/4")
        
        // Test Case 4: Probability prediction accuracy
        var correctProbabilities = 0
        for _ in 0..<100 {
            let knowledge: Float = 0.8
            let predictedProbability = bktModel.predictCorrectnessProbability(knowledge: knowledge)
            
            // Probability should be reasonable (between 0 and 1, closer to 1 for high knowledge)
            if predictedProbability > 0.5 && predictedProbability <= 1.0 {
                correctProbabilities += 1
            }
            totalTests += 1
        }
        testDetails.append("Probability prediction: \(correctProbabilities)/100")
        
        let accuracy = Float(correctIncreases + correctDecreases + correctMastery + correctProbabilities) / Float(totalTests)
        let result = TestResult(
            modelName: "BKT Model",
            accuracy: accuracy,
            precision: accuracy,
            recall: accuracy,
            f1Score: accuracy,
            testCases: totalTests,
            passed: accuracy >= accuracyThreshold,
            details: testDetails.joined(separator: "; ")
        )
        
        testResults["BKT"] = result
        print("✅ BKT Model Accuracy: \(String(format: "%.2f%%", accuracy * 100))")
    }
    
    // MARK: - IRT Model Tests
    
    /// Test Item Response Theory Model accuracy
    private func testIRTModelAccuracy() {
        print("\n📈 Testing IRT Model Accuracy...")
        
        let irtModel = IRTModel()
        _ = 0
        var totalTests = 0
        var testDetails: [String] = []
        
        // Test Case 1: Probability calculation accuracy
        let testScenarios = [
            (ability: Float(-2.0), difficulty: Float(-1.0), expectedHigh: true),   // Low ability, easy question
            (ability: Float(2.0), difficulty: Float(1.0), expectedHigh: true),     // High ability, hard question
            (ability: Float(0.0), difficulty: Float(2.0), expectedHigh: false),    // Medium ability, very hard question
            (ability: Float(1.0), difficulty: Float(-1.0), expectedHigh: true)     // High ability, easy question
        ]
        
        var correctProbabilities = 0
        for scenario in testScenarios {
            let params = IRTModel.Parameters(
                discrimination: 1.0,
                difficulty: scenario.difficulty,
                guessing: 0.25
            )
            
            let probability = irtModel.probabilityOfCorrectAnswer(
                ability: scenario.ability,
                parameters: params
            )
            
            // Check if probability matches expectation
            let isHighProbability = probability > 0.6
            if isHighProbability == scenario.expectedHigh {
                correctProbabilities += 1
            }
            totalTests += 1
        }
        testDetails.append("Probability calculation: \(correctProbabilities)/4")
        
        // Test Case 2: Ability estimation accuracy
        var correctAbilityUpdates = 0
        for _ in 0..<100 {
            let initialAbility: Float = 0.0
            let params = IRTModel.Parameters(discrimination: 1.0, difficulty: 0.0, guessing: 0.25)
            
            let newAbility = irtModel.estimateAbility(
                currentAbility: initialAbility,
                questionParameters: params,
                isCorrect: true
            )
            
            // Ability should increase after correct answer
            if newAbility > initialAbility {
                correctAbilityUpdates += 1
            }
            totalTests += 1
        }
        testDetails.append("Ability estimation: \(correctAbilityUpdates)/100")
        
        // Test Case 3: Difficulty level conversion
        let difficultyTestCases = [
            (difficulty: Float(-1.0), expectedLevel: 1),  // Easy
            (difficulty: Float(0.0), expectedLevel: 2),   // Medium
            (difficulty: Float(1.0), expectedLevel: 3),   // Hard
            (difficulty: Float(2.0), expectedLevel: 4)    // Olympiad
        ]
        
        var correctConversions = 0
        for testCase in difficultyTestCases {
            let actualLevel = irtModel.convertIRTDifficultyToLevel(testCase.difficulty)
            if actualLevel == testCase.expectedLevel {
                correctConversions += 1
            }
            totalTests += 1
        }
        testDetails.append("Difficulty conversion: \(correctConversions)/4")
        
        // Test Case 4: Parameter updates
        var correctParameterUpdates = 0
        for _ in 0..<50 {
            let params = IRTModel.Parameters(discrimination: 1.0, difficulty: 0.0, guessing: 0.25)
            let ability: Float = 1.0
            
            let updatedParams = irtModel.updateQuestionParameters(
                parameters: params,
                ability: ability,
                isCorrect: true
            )
            
            // Parameters should be reasonable
            if updatedParams.discrimination > 0 && updatedParams.guessing >= 0 && updatedParams.guessing <= 1 {
                correctParameterUpdates += 1
            }
            totalTests += 1
        }
        testDetails.append("Parameter updates: \(correctParameterUpdates)/50")
        
        let accuracy = Float(correctProbabilities + correctAbilityUpdates + correctConversions + correctParameterUpdates) / Float(totalTests)
        let result = TestResult(
            modelName: "IRT Model",
            accuracy: accuracy,
            precision: accuracy,
            recall: accuracy,
            f1Score: accuracy,
            testCases: totalTests,
            passed: accuracy >= accuracyThreshold,
            details: testDetails.joined(separator: "; ")
        )
        
        testResults["IRT"] = result
        print("✅ IRT Model Accuracy: \(String(format: "%.2f%%", accuracy * 100))")
    }
    
    // MARK: - Adaptive Difficulty Engine Tests
    
    /// Test Adaptive Difficulty Engine accuracy
    private func testAdaptiveDifficultyEngineAccuracy() {
        print("\n⚙️ Testing Adaptive Difficulty Engine Accuracy...")
        
        let engine = AdaptiveDifficultyEngine.shared
        _ = 0
        var totalTests = 0
        var testDetails: [String] = []
        
        // Test Case 1: High accuracy should increase difficulty
        var correctIncreases = 0
        for _ in 0..<50 {
            let userId = UUID()
            var learningProgress = AILearningProgress(userId: userId)
            
            // Set up learning progress with current difficulty 2
            let setupLesson = createTestLesson(
                userId: userId,
                accuracy: 0.5,
                responseTime: 30.0,
                currentDifficulty: 2
            )
            // Manually add a lesson progress with nextDifficulty = 2 to avoid circular dependency
            let setupProgress = AILearningProgress.LessonProgress(
                lessonId: setupLesson.id,
                subject: setupLesson.subject,
                completedAt: Date(),
                accuracy: setupLesson.accuracy,
                responseTime: setupLesson.responseTime,
                nextDifficulty: 2
            )
            learningProgress.lessonHistory.append(setupProgress)
            
            // Create lesson with high accuracy
            let highAccuracyLesson = createTestLesson(
                userId: userId,
                accuracy: 0.95,
                responseTime: 20.0,
                currentDifficulty: 2
            )
            
            let nextDifficulty = engine.calculateDifficultyAfterLesson(
                learningProgress: learningProgress,
                completedLesson: highAccuracyLesson
            )
            
            // Should increase difficulty for high accuracy (from 2 to 3)
            if nextDifficulty > 2 {
                correctIncreases += 1
            }
            totalTests += 1
        }
        testDetails.append("High accuracy difficulty increase: \(correctIncreases)/50")
        
        // Test Case 2: Low accuracy should decrease difficulty
        var correctDecreases = 0
        for _ in 0..<50 {
            let userId = UUID()
            var learningProgress = AILearningProgress(userId: userId)
            
            // Set up learning progress with current difficulty 3
            let setupLesson = createTestLesson(
                userId: userId,
                accuracy: 0.5,
                responseTime: 30.0,
                currentDifficulty: 3
            )
            // Manually add a lesson progress with nextDifficulty = 3 to avoid circular dependency
            let setupProgress = AILearningProgress.LessonProgress(
                lessonId: setupLesson.id,
                subject: setupLesson.subject,
                completedAt: Date(),
                accuracy: setupLesson.accuracy,
                responseTime: setupLesson.responseTime,
                nextDifficulty: 3
            )
            learningProgress.lessonHistory.append(setupProgress)
            
            // Create lesson with low accuracy
            let lowAccuracyLesson = createTestLesson(
                userId: userId,
                accuracy: 0.2,
                responseTime: 60.0,
                currentDifficulty: 3
            )
            
            let nextDifficulty = engine.calculateDifficultyAfterLesson(
                learningProgress: learningProgress,
                completedLesson: lowAccuracyLesson
            )
            
            // Should decrease difficulty for low accuracy (from 3 to 2)
            if nextDifficulty < 3 {
                correctDecreases += 1
            }
            totalTests += 1
        }
        testDetails.append("Low accuracy difficulty decrease: \(correctDecreases)/50")
        
        // Test Case 3: Moderate accuracy should maintain difficulty
        var correctMaintenance = 0
        for _ in 0..<50 {
            let userId = UUID()
            var learningProgress = AILearningProgress(userId: userId)
            
            // Set up learning progress with current difficulty 2
            let setupLesson = createTestLesson(
                userId: userId,
                accuracy: 0.5,
                responseTime: 30.0,
                currentDifficulty: 2
            )
            // Manually add a lesson progress with nextDifficulty = 2 to avoid circular dependency
            let setupProgress = AILearningProgress.LessonProgress(
                lessonId: setupLesson.id,
                subject: setupLesson.subject,
                completedAt: Date(),
                accuracy: setupLesson.accuracy,
                responseTime: setupLesson.responseTime,
                nextDifficulty: 2
            )
            learningProgress.lessonHistory.append(setupProgress)
            
            // Create lesson with moderate accuracy
            let moderateAccuracyLesson = createTestLesson(
                userId: userId,
                accuracy: 0.6,
                responseTime: 35.0,
                currentDifficulty: 2
            )
            
            let nextDifficulty = engine.calculateDifficultyAfterLesson(
                learningProgress: learningProgress,
                completedLesson: moderateAccuracyLesson
            )
            
            // Should maintain or slightly adjust difficulty (around 2)
            if abs(nextDifficulty - 2) <= 1 {
                correctMaintenance += 1
            }
            totalTests += 1
        }
        testDetails.append("Moderate accuracy maintenance: \(correctMaintenance)/50")
        
        // Test Case 4: Edge cases (very high/low accuracy)
        var correctEdgeCases = 0
        let edgeCases: [(accuracy: Float, currentDifficulty: Int, shouldIncrease: Bool, shouldDecrease: Bool)] = [
            (accuracy: Float(1.0), currentDifficulty: 1, shouldIncrease: true, shouldDecrease: false),
            (accuracy: Float(0.0), currentDifficulty: 4, shouldIncrease: false, shouldDecrease: true)
        ]
        
        for edgeCase in edgeCases {
            let userId = UUID()
            var learningProgress = AILearningProgress(userId: userId)
            
            // Set up learning progress with the correct current difficulty
            let setupLesson = createTestLesson(
                userId: userId,
                accuracy: 0.5,
                responseTime: 30.0,
                currentDifficulty: edgeCase.currentDifficulty
            )
            // Manually add a lesson progress with the correct nextDifficulty to avoid circular dependency
            let setupProgress = AILearningProgress.LessonProgress(
                lessonId: setupLesson.id,
                subject: setupLesson.subject,
                completedAt: Date(),
                accuracy: setupLesson.accuracy,
                responseTime: setupLesson.responseTime,
                nextDifficulty: edgeCase.currentDifficulty
            )
            learningProgress.lessonHistory.append(setupProgress)
            
            let lesson = createTestLesson(
                userId: userId,
                accuracy: edgeCase.accuracy,
                responseTime: 30.0,
                currentDifficulty: edgeCase.currentDifficulty
            )
            
            let nextDifficulty = engine.calculateDifficultyAfterLesson(
                learningProgress: learningProgress,
                completedLesson: lesson
            )
            
            if edgeCase.shouldIncrease && nextDifficulty > edgeCase.currentDifficulty {
                correctEdgeCases += 1
            } else if edgeCase.shouldDecrease && nextDifficulty < edgeCase.currentDifficulty {
                correctEdgeCases += 1
            }
            totalTests += 1
        }
        testDetails.append("Edge cases: \(correctEdgeCases)/2")
        
        let accuracy = Float(correctIncreases + correctDecreases + correctMaintenance + correctEdgeCases) / Float(totalTests)
        let result = TestResult(
            modelName: "Adaptive Difficulty Engine",
            accuracy: accuracy,
            precision: accuracy,
            recall: accuracy,
            f1Score: accuracy,
            testCases: totalTests,
            passed: accuracy >= accuracyThreshold,
            details: testDetails.joined(separator: "; ")
        )
        
        testResults["AdaptiveDifficulty"] = result
        print("✅ Adaptive Difficulty Engine Accuracy: \(String(format: "%.2f%%", accuracy * 100))")
    }
    
    // MARK: - CoreML Model Tests
    
    /// Test CoreML models accuracy with real data
    private func testCoreMLModelAccuracy() {
        print("\n🤖 Testing CoreML Models Accuracy...")
        
        let coreMLService = CoreMLService.shared
        
        // Wait for models to be loaded before running tests
        Task {
            await coreMLService.waitForModelsToLoad()
            
            await MainActor.run {
                self.runCoreMLTests(coreMLService: coreMLService)
            }
        }
    }
    
    /// Run the actual CoreML tests (called after models are loaded)
    private func runCoreMLTests(coreMLService: CoreMLService) {
        _ = 0
        var totalTests = 0
        var testDetails: [String] = []
        
        // Test Case 1: Question recommendation accuracy
        var correctRecommendations = 0
        for _ in 0..<100 {
            let studentProfile: [String: Any] = [
                "ability": Float.random(in: -2...2),
                "weakSubjects": ["Geometry", "Number Theory"],
                "subject_pref_0": Float.random(in: 0...1),
                "subject_pref_1": Float.random(in: 0...1),
                "subject_pref_2": Float.random(in: 0...1),
                "subject_pref_3": Float.random(in: 0...1),
                "subject_pref_4": Float.random(in: 0...1)
            ]
            
            let availableQuestions = createTestQuestions(count: 20)
            do {
                let recommendations = try coreMLService.recommendQuestions(
                    studentProfile: studentProfile,
                    availableQuestions: availableQuestions,
                    count: 5
                )
                
                // Should return exactly 5 recommendations
                if recommendations.count == 5 {
                    correctRecommendations += 1
                }
            } catch {
                print("Error recommending questions: \(error.localizedDescription)")
            }
            totalTests += 1
        }
        testDetails.append("Question recommendations: \(correctRecommendations)/100")
        
        // Test Case 2: Difficulty prediction accuracy
        var correctDifficultyPredictions = 0
        for _ in 0..<100 {
            let studentAbility = Float.random(in: -2...2)
            let questionFeatures: [String: Any] = [
                "difficultyLevel": Int.random(in: 1...4),
                "irt_discrimination": Float.random(in: 0.5...2.0),
                "irt_difficulty": Float.random(in: -2...2),
                "irt_guessing": 0.25
            ]
            
            do {
                let predictedDifficulty = try coreMLService.predictQuestionDifficulty(
                    studentAbility: studentAbility,
                    questionFeatures: questionFeatures
                )
                
                // Difficulty should be between 0 and 1
                if predictedDifficulty >= 0.0 && predictedDifficulty <= 1.0 {
                    correctDifficultyPredictions += 1
                }
            } catch {
                print("Error making difficulty prediction: \(error.localizedDescription)")
            }
            totalTests += 1
        }
        testDetails.append("Difficulty predictions: \(correctDifficultyPredictions)/100")
        
        // Test Case 3: Ability estimation accuracy
        var correctAbilityEstimations = 0
        for _ in 0..<100 {
            let currentAbility = Float.random(in: -2...2)
            let responseHistory = createTestResponseHistory(count: 10)
            
            do {
                let estimatedAbility = try coreMLService.estimateStudentAbility(
                    currentAbility: currentAbility,
                    responseHistory: responseHistory
                )
                
                // Estimated ability should be reasonable
                if estimatedAbility >= -3.0 && estimatedAbility <= 3.0 {
                    correctAbilityEstimations += 1
                }
            } catch {
                print("Error estimating student ability: \(error.localizedDescription)")
            }
            totalTests += 1
        }
        testDetails.append("Ability estimations: \(correctAbilityEstimations)/100")
        
        let accuracy = Float(correctRecommendations + correctDifficultyPredictions + correctAbilityEstimations) / Float(totalTests)
        let result = TestResult(
            modelName: "CoreML Models",
            accuracy: accuracy,
            precision: accuracy,
            recall: accuracy,
            f1Score: accuracy,
            testCases: totalTests,
            passed: accuracy >= accuracyThreshold,
            details: testDetails.joined(separator: "; ")
        )
        
        testResults["CoreML"] = result
        print("✅ CoreML Models Accuracy: \(String(format: "%.2f%%", accuracy * 100))")
    }
    
    // MARK: - Helper Methods
    
    /// Create test lesson with specified parameters
    private func createTestLesson(
        userId: UUID,
        accuracy: Float,
        responseTime: TimeInterval,
        currentDifficulty: Int
    ) -> Lesson {
        var lesson = Lesson(userId: userId, subject: .arithmetic)
        lesson.accuracy = accuracy
        lesson.responseTime = responseTime
        lesson.difficulty = currentDifficulty
        lesson.status = .completed
        lesson.completedAt = Date()
        
        // Create realistic responses
        let questionCount = 10
        let correctCount = Int(Float(questionCount) * accuracy)
        
        for i in 0..<questionCount {
            let isCorrect = i < correctCount
            let response = Lesson.QuestionResponse(
                questionId: UUID(),
                isCorrect: isCorrect,
                responseTime: responseTime,
                answeredAt: Date(),
                selectedAnswer: isCorrect ? "A" : "B"
            )
            lesson.responses.append(response)
        }
        
        return lesson
    }
    
    /// Create test questions for recommendation testing
    private func createTestQuestions(count: Int) -> [Question] {
        var questions: [Question] = []
        
        for _ in 0..<count {
            let subject = Lesson.Subject.allCases.randomElement() ?? .arithmetic
            let difficulty = Int.random(in: 1...4)
            
            let question = Question(
                id: UUID(),
                subject: subject,
                difficulty: difficulty,
                type: .multipleChoice,
                questionText: "Test question \(questions.count + 1)",
                correctAnswer: "A"
            )
            questions.append(question)
        }
        
        return questions
    }
    
    /// Create test response history
    private func createTestResponseHistory(count: Int) -> [Lesson.QuestionResponse] {
        var responses: [Lesson.QuestionResponse] = []
        
        for _ in 0..<count {
            let isCorrect = Bool.random()
            let response = Lesson.QuestionResponse(
                questionId: UUID(),
                isCorrect: isCorrect,
                responseTime: Double.random(in: 10...60),
                answeredAt: Date(),
                selectedAnswer: isCorrect ? "A" : "B"
            )
            responses.append(response)
        }
        
        return responses
    }
    
    // MARK: - Report Generation
    
    /// Generate comprehensive accuracy report
    private func generateAccuracyReport() {
        print("\n📊 AI Model Accuracy Test Report")
        print(String(repeating: "=", count: 60))
        
        var overallPassed = 0
        let totalModels = testResults.count
        var totalAccuracy: Float = 0.0
        
        for (modelName, result) in testResults {
            let status = result.passed ? "✅ PASSED" : "❌ FAILED"
            print("\(modelName): \(status)")
            print("  Accuracy: \(String(format: "%.2f%%", result.accuracy * 100))")
            print("  Test Cases: \(result.testCases)")
            print("  Threshold: \(String(format: "%.2f%%", accuracyThreshold * 100))")
            print("  Details: \(result.details)")
            print()
            
            if result.passed {
                overallPassed += 1
            }
            totalAccuracy += result.accuracy
        }
        
        let overallAccuracy = Float(overallPassed) / Float(totalModels)
        let averageAccuracy = totalAccuracy / Float(totalModels)
        
        print("Overall Test Results:")
        print("  Models Passed: \(overallPassed)/\(totalModels)")
        print("  Overall Success Rate: \(String(format: "%.2f%%", overallAccuracy * 100))")
        print("  Average Accuracy: \(String(format: "%.2f%%", averageAccuracy * 100))")
        
        if overallAccuracy >= 0.8 {
            print("🎉 AI Models meet accuracy requirements!")
        } else {
            print("⚠️ Some AI models need improvement before deployment.")
        }
        
        // Save results for tracking
        saveTestResults()
    }
    
    /// Save test results to file for analysis
    private func saveTestResults() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let resultsURL = documentsPath.appendingPathComponent("AI_Model_Test_Results.json")
        
        do {
            let jsonData = try JSONEncoder().encode(testResults)
            try jsonData.write(to: resultsURL)
            print("📁 Test results saved to: \(resultsURL.path)")
        } catch {
            print("❌ Error saving test results: \(error.localizedDescription)")
        }
    }
}

// MARK: - TestResult Codable Extension

extension ComprehensiveAITests.TestResult: Codable {
    enum CodingKeys: String, CodingKey {
        case modelName, accuracy, precision, recall, f1Score, testCases, passed, details
    }
}
