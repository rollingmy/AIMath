import Foundation

/// Implements Bayesian Knowledge Tracing (BKT) for estimating student mastery of concepts
public class BKTModel {
    /// Default parameters if not explicitly specified
    public struct Parameters {
        /// Probability of learning a concept after an opportunity (default 0.4)
        public let pLearn: Float
        
        /// Probability of guessing correctly despite not knowing concept (default 0.25)
        public let pGuess: Float
        
        /// Probability of answering incorrectly despite knowing concept (default 0.1)
        public let pSlip: Float
        
        /// Prior probability of knowing the concept (default 0.5)
        public let pKnown: Float
        
        /// Probability of forgetting a learned concept (default 0.05)
        public let pForget: Float
        
        /// Create BKT parameters with default values
        public init(
            pLearn: Float = 0.4,
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
    
    /// Parameters for this BKT model
    private let parameters: Parameters
    
    /// Initialize with custom parameters
    /// - Parameter parameters: The BKT parameters to use
    public init(parameters: Parameters = Parameters()) {
        self.parameters = parameters
    }
    
    /// Update knowledge state based on student response
    /// - Parameters:
    ///   - priorKnowledge: Prior probability of student knowing the concept
    ///   - isCorrect: Whether the student answered correctly
    /// - Returns: Updated probability of concept mastery
    public func updateKnowledge(priorKnowledge: Float, isCorrect: Bool) -> Float {
        let pLearned = priorKnowledge
        let pNotLearned = 1.0 - pLearned
        
        // Calculate conditional probabilities
        // P(correct | learned) and P(correct | not learned)
        let pCorrectGivenLearned = 1.0 - parameters.pSlip
        let pCorrectGivenNotLearned = parameters.pGuess
        
        // Calculate joint probabilities
        // P(correct, learned) and P(correct, not learned)
        let pCorrectAndLearned = pCorrectGivenLearned * pLearned
        let pCorrectAndNotLearned = pCorrectGivenNotLearned * pNotLearned
        
        // Calculate P(correct) = P(correct, learned) + P(correct, not learned)
        let pCorrect = pCorrectAndLearned + pCorrectAndNotLearned
        
        // Apply Bayes' theorem to get P(learned | correct or incorrect)
        var knowledge: Float
        if isCorrect {
            // P(learned | correct) = P(correct | learned) * P(learned) / P(correct)
            knowledge = pCorrectAndLearned / pCorrect
        } else {
            // P(learned | incorrect) = P(incorrect | learned) * P(learned) / P(incorrect)
            let pIncorrectGivenLearned = parameters.pSlip
            let pIncorrectGivenNotLearned = 1.0 - parameters.pGuess
            let pIncorrectAndLearned = pIncorrectGivenLearned * pLearned
            let pIncorrect = pIncorrectAndLearned + (pIncorrectGivenNotLearned * pNotLearned)
            knowledge = pIncorrectAndLearned / pIncorrect
        }
        
        // Apply learning rate for students who haven't mastered the concept yet
        knowledge = knowledge + ((1.0 - knowledge) * parameters.pLearn)
        
        // Apply forgetting rate (decay of knowledge over time)
        // This is simplified here, as a more accurate model would consider time elapsed
        knowledge = max(0.0, knowledge - parameters.pForget)
        
        return knowledge
    }
    
    /// Determine concept mastery based on knowledge probability
    /// - Parameter knowledge: The knowledge probability (0.0 - 1.0)
    /// - Returns: Whether the concept is considered mastered
    public func isConceptMastered(knowledge: Float) -> Bool {
        return knowledge >= 0.85  // 85% threshold for mastery
    }
    
    /// Predict probability of student answering correctly
    /// - Parameter knowledge: Current knowledge probability
    /// - Returns: Probability of correct answer
    public func predictCorrectnessProbability(knowledge: Float) -> Float {
        // P(correct) = P(correct | learned) * P(learned) + P(correct | not learned) * P(not learned)
        let pLearned = knowledge
        let pNotLearned = 1.0 - pLearned
        let pCorrectGivenLearned = 1.0 - parameters.pSlip
        let pCorrectGivenNotLearned = parameters.pGuess
        
        return (pCorrectGivenLearned * pLearned) + (pCorrectGivenNotLearned * pNotLearned)
    }
    
    /// Create BKT parameters from question JSON data
    /// - Parameter questionParams: Dictionary of BKT parameters from question JSON
    /// - Returns: BKT parameters
    public static func parametersFromJSON(_ questionParams: [String: Any]?) -> Parameters {
        guard let params = questionParams as? [String: Float] else {
            return Parameters()
        }
        
        return Parameters(
            pLearn: params["pLearn"] ?? 0.4,
            pGuess: params["pGuess"] ?? 0.25,
            pSlip: params["pSlip"] ?? 0.1,
            pKnown: params["pKnown"] ?? 0.5,
            pForget: params["pForget"] ?? 0.05
        )
    }
    
    /// Update BKT model with data from a completed lesson
    /// - Parameters:
    ///   - lesson: The completed lesson with question responses
    ///   - userId: The student's user ID
    public func updateWithLesson(_ lesson: Lesson, userId: UUID) {
        guard lesson.status == .completed, lesson.questions.count > 0 else {
            return // Only process completed lessons with questions
        }
        
        // Get the current knowledge state for this user and subject
        let userDefaultsKey = "BKT_\(userId)_\(lesson.subject.rawValue)"
        let priorKnowledge = UserDefaults.standard.float(forKey: userDefaultsKey)
        
        // Start with prior knowledge or default if not available
        var currentKnowledge: Float = priorKnowledge > 0 ? priorKnowledge : parameters.pKnown
        
        // Process each question response to update the knowledge state
        for response in lesson.responses {
            // Update knowledge based on correctness
            currentKnowledge = updateKnowledge(
                priorKnowledge: currentKnowledge,
                isCorrect: response.isCorrect
            )
        }
        
        // Store the updated knowledge state
        UserDefaults.standard.set(currentKnowledge, forKey: userDefaultsKey)
        
        // Also store whether the concept is now considered mastered
        let isMasteredKey = "BKT_Mastered_\(userId)_\(lesson.subject.rawValue)"
        UserDefaults.standard.set(
            isConceptMastered(knowledge: currentKnowledge),
            forKey: isMasteredKey
        )
    }
} 