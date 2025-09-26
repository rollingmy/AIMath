import Foundation

/// Represents a learning session with questions and performance metrics
public struct Lesson: Identifiable, Codable, Equatable {
    /// Unique identifier for the lesson
    public let id: UUID
    
    /// Reference to the user taking this lesson
    public let userId: UUID
    
    /// Subject category of the lesson
    public let subject: Subject
    
    /// Difficulty level of the lesson (1-4)
    public var difficulty: Int
    
    /// Array of question IDs in this lesson
    public var questions: [UUID]
    
    /// Tracks responses for each question
    public var responses: [QuestionResponse]
    
    /// Percentage of correct answers (0-100)
    public var accuracy: Float
    
    /// Average response time in seconds
    public var responseTime: TimeInterval
    
    /// When the lesson was started
    public let startedAt: Date
    
    /// When the lesson was completed
    public var completedAt: Date?
    
    /// Lesson status tracking
    public var status: LessonStatus
}

// MARK: - Supporting Types
extension Lesson {
    /// Tracks individual question responses
    public struct QuestionResponse: Codable, Equatable {
        public let questionId: UUID
        public let isCorrect: Bool
        public let responseTime: TimeInterval
        public let answeredAt: Date
        /// The user's selected answer label (e.g., "A", "B", "C", "D") if applicable
        public let selectedAnswer: String?
    }
    
    /// Available subject categories
    public enum Subject: String, Codable {
        case logicalThinking = "logical_thinking"
        case arithmetic
        case numberTheory = "number_theory"
        case geometry
        case combinatorics
    }
    
    /// Status of the lesson
    public enum LessonStatus: String, Codable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case completed
    }
    
    /// Updates lesson progress with new question response
    mutating func updateProgress(questionId: UUID, isCorrect: Bool, responseTime: TimeInterval) {
        // Add response
        let response = QuestionResponse(
            questionId: questionId,
            isCorrect: isCorrect,
            responseTime: responseTime,
            answeredAt: Date(),
            selectedAnswer: nil
        )
        responses.append(response)
        
        // Update accuracy
        let correctCount = responses.filter { $0.isCorrect }.count
        accuracy = Float(correctCount) / Float(responses.count)
        
        // Update average response time
        self.responseTime = responses.map { $0.responseTime }.reduce(0, +) / Double(responses.count)
        
        // Update status
        if responses.count == questions.count {
            status = .completed
            completedAt = Date()
        } else {
            status = .inProgress
        }
    }
    
    /// Convenience initialization
    public init(userId: UUID, subject: Subject) {
        self.id = UUID()
        self.userId = userId
        self.subject = subject
        self.difficulty = 1
        self.questions = []
        self.responses = []
        self.accuracy = 0.0
        self.responseTime = 0.0
        self.startedAt = Date()
        self.completedAt = nil
        self.status = .notStarted
    }
}

// MARK: - Core Data Integration
// Note: Core Data integration is handled in CoreDataExtensions.swift

// MARK: - Analytics & Progress Tracking
extension Lesson {
    /// Validates lesson data before saving
    func validate() throws {
        guard !questions.isEmpty else {
            throw ValidationError.noQuestions
        }
        guard (0...100).contains(Int(accuracy * 100)) else {
            throw ValidationError.invalidAccuracy
        }
        guard responseTime >= 0 else {
            throw ValidationError.invalidResponseTime
        }
    }
    
    enum ValidationError: LocalizedError {
        case noQuestions
        case invalidAccuracy
        case invalidResponseTime
        
        var errorDescription: String? {
            switch self {
            case .noQuestions:
                return "Lesson must contain at least one question"
            case .invalidAccuracy:
                return "Accuracy must be between 0 and 100%"
            case .invalidResponseTime:
                return "Response time cannot be negative"
            }
        }
    }
} 