import Foundation

/// Implements Item Response Theory (IRT) for mapping question difficulty to student ability
public class IRTModel {
    /// Parameters for the IRT model
    public struct Parameters: Codable {
        /// Discrimination parameter (how well the question differentiates between skill levels)
        public let discrimination: Float
        
        /// Difficulty parameter (higher = more difficult)
        public let difficulty: Float
        
        /// Guessing parameter (lower bound on probability of correct answer)
        public let guessing: Float
        
        /// Initialize with default values
        public init(
            discrimination: Float = 1.0,
            difficulty: Float = 0.0,
            guessing: Float = 0.25
        ) {
            self.discrimination = discrimination
            self.difficulty = difficulty
            self.guessing = guessing
        }
    }
    
    /// BKT model parameters
    public struct BKTParameters: Codable {
        public let pLearn: Float
        public let pGuess: Float
        public let pSlip: Float
        public let pKnown: Float
        public let pForget: Float
        
        public init(
            pLearn: Float = 0.2,
            pGuess: Float = 0.25,
            pSlip: Float = 0.1,
            pKnown: Float = 0.5,
            pForget: Float = 0.05
        ) {
            self.pLearn = pLearn
            self.pGuess = pGuess
            self.pSlip = pSlip
            self.pKnown = pKnown
            self.pForget = pForget
        }
    }
    
    /// Calculate probability of a correct answer using 3-parameter logistic IRT model
    /// - Parameters:
    ///   - ability: Student's ability level (theta)
    ///   - parameters: IRT parameters for the question
    /// - Returns: Probability of correct answer (0.0 - 1.0)
    public func probabilityOfCorrectAnswer(ability: Float, parameters: Parameters) -> Float {
        // 3-parameter logistic model:
        // P(correct) = c + (1-c) / (1 + e^(-a(θ-b)))
        // where:
        //   c = guessing parameter
        //   a = discrimination parameter
        //   b = difficulty parameter
        //   θ = student ability level
        
        let exponent = -parameters.discrimination * (ability - parameters.difficulty)
        let probability = parameters.guessing + (1.0 - parameters.guessing) / (1.0 + exp(exponent))
        
        // Ensure probability is within valid range
        return min(1.0, max(0.0, probability))
    }
    
    /// Estimate student ability level based on response pattern
    /// - Parameters:
    ///   - currentAbility: Current estimate of student ability
    ///   - questionParameters: IRT parameters for the question
    ///   - isCorrect: Whether the answer was correct
    ///   - learningRate: How quickly to adjust ability estimate (default 0.1)
    /// - Returns: Updated ability estimate
    public func estimateAbility(
        currentAbility: Float,
        questionParameters: Parameters,
        isCorrect: Bool,
        learningRate: Float = 0.1
    ) -> Float {
        // Calculate expected probability of correct answer
        let expectedProbability = probabilityOfCorrectAnswer(
            ability: currentAbility,
            parameters: questionParameters
        )
        
        // Calculate observed outcome (1.0 for correct, 0.0 for incorrect)
        let observed: Float = isCorrect ? 1.0 : 0.0
        
        // Update ability estimate using gradient descent approach
        // θ_new = θ_old + learning_rate * (observed - expected)
        let abilityUpdate = learningRate * (observed - expectedProbability)
        return currentAbility + abilityUpdate
    }
    
    /// Update question parameters based on student responses
    /// - Parameters:
    ///   - parameters: Current IRT parameters for the question
    ///   - ability: Student's ability level
    ///   - isCorrect: Whether the answer was correct
    ///   - learningRate: How quickly to adjust parameters (default 0.05)
    /// - Returns: Updated IRT parameters
    public func updateQuestionParameters(
        parameters: Parameters,
        ability: Float,
        isCorrect: Bool,
        learningRate: Float = 0.05
    ) -> Parameters {
        // Calculate expected probability of correct answer
        let expectedProbability = probabilityOfCorrectAnswer(
            ability: ability,
            parameters: parameters
        )
        
        // Calculate observed outcome (1.0 for correct, 0.0 for incorrect)
        let observed: Float = isCorrect ? 1.0 : 0.0
        
        // Update difficulty parameter
        // If student answers correctly but probability was low, decrease difficulty
        // If student answers incorrectly but probability was high, increase difficulty
        let difficultyUpdate = learningRate * (expectedProbability - observed)
        let newDifficulty = parameters.difficulty + difficultyUpdate
        
        // Update discrimination parameter
        // If student's ability is far from difficulty and answer aligns with expectation,
        // increase discrimination. Otherwise, decrease it.
        let abilityDiffMagnitude = abs(ability - parameters.difficulty)
        let correctnessFactor: Float = (observed == 1.0 && ability > parameters.difficulty) ||
                                       (observed == 0.0 && ability < parameters.difficulty) ?
                                       1.0 : -1.0
        let discriminationUpdate = learningRate * abilityDiffMagnitude * correctnessFactor
        let newDiscrimination = max(0.2, min(2.0, parameters.discrimination + discriminationUpdate))
        
        // Guessing parameter usually doesn't update frequently, but can be adjusted
        // based on low-ability students who answer correctly
        var newGuessing = parameters.guessing
        if isCorrect && ability < parameters.difficulty - 1.0 {
            newGuessing = min(0.5, parameters.guessing + (learningRate * 0.1))
        }
        
        return Parameters(
            discrimination: newDiscrimination,
            difficulty: newDifficulty,
            guessing: newGuessing
        )
    }
    
    /// Convert IRT difficulty parameter to integer difficulty level (1-4)
    /// - Parameter difficulty: IRT difficulty parameter
    /// - Returns: Integer difficulty level
    public func convertIRTDifficultyToLevel(_ difficulty: Float) -> Int {
        switch difficulty {
        case ..<(-0.5):
            return 1  // Easy
        case (-0.5)..<0.5:
            return 2  // Medium
        case 0.5..<1.5:
            return 3  // Hard
        default:
            return 4  // Olympiad
        }
    }
    
    /// Create IRT parameters from question JSON data
    /// - Parameter questionParams: Dictionary of IRT parameters from question JSON
    /// - Returns: IRT parameters
    public static func parametersFromJSON(_ questionParams: [String: Any]?) -> Parameters {
        guard let params = questionParams as? [String: Float] else {
            return Parameters()
        }
        
        return Parameters(
            discrimination: params["discrimination"] ?? 1.0,
            difficulty: params["difficulty"] ?? 0.0,
            guessing: params["guessing"] ?? 0.25
        )
    }
    
    /// Update IRT model with data from a completed lesson
    /// - Parameters:
    ///   - lesson: The completed lesson with question responses
    ///   - userId: The student's user ID
    public func updateWithLesson(_ lesson: Lesson, userId: UUID) async {
        guard lesson.status == .completed, lesson.questions.count > 0 else {
            return // Only process completed lessons with questions
        }
        
        // Get the current ability estimate for this user
        let userDefaultsKey = "IRT_Ability_\(userId)"
        let currentAbility = UserDefaults.standard.float(forKey: userDefaultsKey)
        
        // Start with current ability or default if not available
        var ability: Float = currentAbility != 0 ? currentAbility : 0.0
        
        // Get current question parameters or use defaults
        let questionService: QuestionService = QuestionService.shared
        
        // Process each question response to update ability and question parameters
        for response in lesson.responses {
            do {
                if let question = try await questionService.getQuestion(id: response.questionId) {
                    // Extract IRT parameters from question metadata or use defaults
                    let parameters: Parameters
                    
                    // Approach without ambiguous type expressions
                    if let metadata = question.metadata {
                        if let irtDict = metadata["irt"] as? [String: Any] {
                            let discrimination = (irtDict["discrimination"] as? NSNumber)?.floatValue ?? 1.0
                            let difficulty = (irtDict["difficulty"] as? NSNumber)?.floatValue ?? 0.0
                            let guessing = (irtDict["guessing"] as? NSNumber)?.floatValue ?? 0.25
                            
                            parameters = Parameters(
                                discrimination: discrimination,
                                difficulty: difficulty,
                                guessing: guessing
                            )
                        } else {
                            // Default parameters based on question difficulty level
                            let difficultyLevel = question.difficulty
                            let difficultyParam: Float = Float(difficultyLevel) * 0.5 - 1.0
                            parameters = Parameters(
                                discrimination: 1.0,
                                difficulty: difficultyParam,
                                guessing: 0.25
                            )
                        }
                    } else {
                        // Default parameters based on question difficulty level
                        let difficultyLevel = question.difficulty
                        let difficultyParam: Float = Float(difficultyLevel) * 0.5 - 1.0
                        parameters = Parameters(
                            discrimination: 1.0,
                            difficulty: difficultyParam,
                            guessing: 0.25
                        )
                    }
                    
                    // Update ability estimate
                    ability = estimateAbility(
                        currentAbility: ability,
                        questionParameters: parameters,
                        isCorrect: response.isCorrect
                    )
                    
                    // Update question parameters
                    let updatedParameters = updateQuestionParameters(
                        parameters: parameters,
                        ability: ability,
                        isCorrect: response.isCorrect
                    )
                    
                    // Store updated parameters for the question
                    // In a real implementation, you would store these persistently
                    // Here we'll use a user default as a simple example
                    let questionParamKey = "IRT_Question_\(response.questionId)"
                    
                    // Store as raw values
                    let paramDict: [String: Float] = [
                        "discrimination": updatedParameters.discrimination,
                        "difficulty": updatedParameters.difficulty,
                        "guessing": updatedParameters.guessing
                    ]
                    UserDefaults.standard.set(paramDict, forKey: questionParamKey)
                }
            } catch {
                print("Error processing question: \(error.localizedDescription)")
                continue
            }
        }
        
        // Store the updated ability estimate
        UserDefaults.standard.set(ability, forKey: userDefaultsKey)
        
        // Also update ability for specific subject
        let subjectAbilityKey = "IRT_Ability_\(userId)_\(lesson.subject.rawValue)"
        UserDefaults.standard.set(ability, forKey: subjectAbilityKey)
    }
} 