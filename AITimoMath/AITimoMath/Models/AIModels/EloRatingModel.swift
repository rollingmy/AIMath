import Foundation

/// Implements the Elo Rating System for difficulty adjustments in the adaptive learning engine
public class EloRatingModel {
    // Constants for Elo calculation
    private let kFactor: Float = 32.0       // Controls sensitivity to changes
    private let defaultRating: Float = 1200  // Default rating for new students/questions
    
    /// Calculate new student rating based on performance
    /// - Parameters:
    ///   - currentRating: Student's current Elo rating
    ///   - questionDifficulty: Question's difficulty rating
    ///   - isCorrect: Whether the student answered correctly
    ///   - responseTime: Time taken to answer (in seconds)
    /// - Returns: New student rating
    public func calculateNewStudentRating(
        currentRating: Float,
        questionDifficulty: Float,
        isCorrect: Bool,
        responseTime: TimeInterval
    ) -> Float {
        // Calculate expected score (probability of answering correctly)
        let expectedScore = calculateExpectedScore(
            studentRating: currentRating,
            questionDifficulty: questionDifficulty
        )
        
        // Calculate actual score (1.0 for correct, 0.0 for incorrect)
        // We can also factor in response time to give partial credit for slow correct answers
        let actualScore: Float
        if isCorrect {
            // Adjust score based on response time (faster = higher score)
            let timeLimit: TimeInterval = 60.0  // 60 seconds as default time limit
            let timeBonus = Float(max(0, 1.0 - responseTime / timeLimit))
            actualScore = 1.0 - (0.2 * (1.0 - timeBonus))  // Between 0.8 and 1.0 for correct answers
        } else {
            actualScore = 0.0
        }
        
        // Apply Elo formula: NewRating = CurrentRating + K × (ActualScore − ExpectedScore)
        let ratingChange = kFactor * (actualScore - expectedScore)
        return currentRating + ratingChange
    }
    
    /// Calculate new question difficulty based on student performance
    /// - Parameters:
    ///   - currentDifficulty: Question's current difficulty rating
    ///   - studentRating: Student's Elo rating
    ///   - isCorrect: Whether the student answered correctly
    ///   - responseTime: Time taken to answer (in seconds)
    /// - Returns: New question difficulty rating
    public func calculateNewQuestionDifficulty(
        currentDifficulty: Float,
        studentRating: Float,
        isCorrect: Bool,
        responseTime: TimeInterval
    ) -> Float {
        // Calculate expected score for this matchup
        let expectedScore = calculateExpectedScore(
            studentRating: studentRating,
            questionDifficulty: currentDifficulty
        )
        
        // Calculate actual score (1.0 for correct, 0.0 for incorrect)
        let actualScore: Float = isCorrect ? 1.0 : 0.0
        
        // For questions, we invert the formula since a student getting a question correct
        // means the question might be too easy (and should lose rating points)
        // When student gets it correct (actualScore = 1.0), question should become easier (lower rating)
        // When student gets it wrong (actualScore = 0.0), question should become harder (higher rating)
        let ratingChange = kFactor * (actualScore - expectedScore)
        return currentDifficulty + ratingChange
    }
    
    /// Convert Elo rating to difficulty level (1-4)
    /// - Parameter eloRating: The Elo rating to convert
    /// - Returns: Integer difficulty level from 1 (easiest) to 4 (hardest)
    public func convertEloToDifficultyLevel(_ eloRating: Float) -> Int {
        switch eloRating {
        case ..<1100:
            return 1  // Easy
        case 1100..<1300:
            return 2  // Medium
        case 1300..<1500:
            return 3  // Hard
        default:
            return 4  // Olympiad
        }
    }
    
    /// Convert difficulty level (1-4) to Elo rating
    /// - Parameter difficultyLevel: Integer difficulty level
    /// - Returns: Corresponding Elo rating
    public func convertDifficultyLevelToElo(_ difficultyLevel: Int) -> Float {
        switch difficultyLevel {
        case 1:
            return 1000  // Easy
        case 2:
            return 1200  // Medium
        case 3:
            return 1400  // Hard
        case 4:
            return 1600  // Olympiad
        default:
            return defaultRating
        }
    }
    
    /// Calculate expected score based on ratings difference
    /// - Parameters:
    ///   - studentRating: Student's Elo rating
    ///   - questionDifficulty: Question's difficulty rating
    /// - Returns: Expected score between 0.0 and 1.0
    private func calculateExpectedScore(studentRating: Float, questionDifficulty: Float) -> Float {
        // Use the Elo formula: 1 / (1 + 10^((questionDifficulty - studentRating) / 400))
        let exponent = (questionDifficulty - studentRating) / 400.0
        return 1.0 / (1.0 + pow(10, exponent))
    }
    
    /// Update student's Elo rating based on lesson performance
    /// - Parameters:
    ///   - userId: The student's user ID
    ///   - lesson: The completed lesson with question responses
    public func updateRating(for userId: UUID, lesson: Lesson) async {
        guard lesson.status == .completed, lesson.questions.count > 0 else {
            return // Only process completed lessons with questions
        }
        
        // Get the current Elo rating for this user
        let userDefaultsKey = "Elo_Rating_\(userId)"
        let currentRating = UserDefaults.standard.float(forKey: userDefaultsKey)
        
        // Start with current rating or default if not available
        var studentRating: Float = currentRating > 0 ? currentRating : defaultRating
        
        // Get current question difficulties or use defaults based on level
        let questionService = QuestionService.shared
        
        // Process each question response to update student rating and question difficulty
        for response in lesson.responses {
            do {
                if let question = try await questionService.getQuestion(id: response.questionId) {
                    // Get question difficulty as Elo rating
                    let questionKey = "Elo_Question_\(response.questionId)"
                    var questionDifficulty = UserDefaults.standard.float(forKey: questionKey)
                    
                    // If no stored difficulty, use default based on question level
                    if questionDifficulty == 0 {
                        questionDifficulty = convertDifficultyLevelToElo(question.difficulty)
                    }
                    
                    // Update student rating
                    studentRating = calculateNewStudentRating(
                        currentRating: studentRating,
                        questionDifficulty: questionDifficulty,
                        isCorrect: response.isCorrect,
                        responseTime: response.responseTime
                    )
                    
                    // Update question difficulty
                    let newQuestionDifficulty = calculateNewQuestionDifficulty(
                        currentDifficulty: questionDifficulty,
                        studentRating: studentRating,
                        isCorrect: response.isCorrect,
                        responseTime: response.responseTime
                    )
                    
                    // Store updated question difficulty
                    UserDefaults.standard.set(newQuestionDifficulty, forKey: questionKey)
                }
            } catch {
                print("Error processing question: \(error.localizedDescription)")
                continue
            }
        }
        
        // Store the updated student rating
        UserDefaults.standard.set(studentRating, forKey: userDefaultsKey)
        
        // Also store rating for specific subject
        let subjectRatingKey = "Elo_Rating_\(userId)_\(lesson.subject.rawValue)"
        UserDefaults.standard.set(studentRating, forKey: subjectRatingKey)
    }
} 