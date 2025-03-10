import Foundation
import CloudKit

/// Represents a math question in the TIMO curriculum
public struct Question: Identifiable, Codable, Equatable {
    /// Unique identifier for the question
    public let id: UUID
    
    /// Subject category
    public let subject: Lesson.Subject
    
    /// Difficulty rating (1-4: Easy, Medium, Hard, Olympiad)
    public var difficulty: Int
    
    /// Type of question (multiple choice or open-ended)
    public let type: QuestionType
    
    /// The actual question text
    public let questionText: String
    
    /// Multiple choice options (if applicable)
    public var options: [String]?
    
    /// Correct answer
    public let correctAnswer: String
    
    /// Optional hint for students
    public var hint: String?
    
    /// Optional image URL for visual questions
    public var imageUrl: URL?
}

// MARK: - Supporting Types
extension Question {
    public enum QuestionType: String, Codable {
        case multipleChoice = "mcq"
        case openEnded = "open_ended"
    }
    
    /// Convenience initialization
    public init(
        subject: Lesson.Subject,
        difficulty: Int,
        type: QuestionType,
        questionText: String,
        correctAnswer: String
    ) {
        self.id = UUID()
        self.subject = subject
        self.difficulty = difficulty
        self.type = type
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.options = type == .multipleChoice ? [] : nil
        self.hint = nil
        self.imageUrl = nil
    }
}

// MARK: - CloudKit Integration
extension Question {
    static let recordType = "Question"
    
    /// Converts Question model to CloudKit record
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Question.recordType)
        record["id"] = id.uuidString
        record["subject"] = subject.rawValue
        record["difficulty"] = difficulty
        record["type"] = type.rawValue
        record["questionText"] = questionText
        record["options"] = options
        record["correctAnswer"] = correctAnswer
        record["hint"] = hint
        record["imageUrl"] = imageUrl?.absoluteString
        return record
    }
    
    /// Creates Question model from CloudKit record
    init?(from record: CKRecord) {
        guard
            let idString = record["id"] as? String,
            let id = UUID(uuidString: idString),
            let subjectString = record["subject"] as? String,
            let subject = Lesson.Subject(rawValue: subjectString),
            let difficulty = record["difficulty"] as? Int,
            let typeString = record["type"] as? String,
            let type = QuestionType(rawValue: typeString),
            let questionText = record["questionText"] as? String,
            let correctAnswer = record["correctAnswer"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.subject = subject
        self.difficulty = difficulty
        self.type = type
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.options = record["options"] as? [String]
        self.hint = record["hint"] as? String
        if let urlString = record["imageUrl"] as? String {
            self.imageUrl = URL(string: urlString)
        }
    }
}

// MARK: - Validation
extension Question {
    /// Validates question data before saving
    func validate() throws {
        // Question text validation
        guard !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyQuestionText
        }
        guard questionText.count <= 500 else {
            throw ValidationError.questionTextTooLong
        }
        
        // Difficulty validation
        guard (1...4).contains(difficulty) else {
            throw ValidationError.invalidDifficulty
        }
        
        // Multiple choice options validation
        if type == .multipleChoice {
            guard let options = options, !options.isEmpty else {
                throw ValidationError.missingOptions
            }
            guard options.count >= 2 && options.count <= 5 else {
                throw ValidationError.invalidOptionsCount
            }
            guard options.contains(correctAnswer) else {
                throw ValidationError.correctAnswerNotInOptions
            }
        }
    }
    
    /// Validation error types
    enum ValidationError: LocalizedError {
        case emptyQuestionText
        case questionTextTooLong
        case invalidDifficulty
        case missingOptions
        case invalidOptionsCount
        case correctAnswerNotInOptions
        
        var errorDescription: String? {
            switch self {
            case .emptyQuestionText:
                return "Question text cannot be empty"
            case .questionTextTooLong:
                return "Question text cannot exceed 500 characters"
            case .invalidDifficulty:
                return "Difficulty must be between 1 and 4"
            case .missingOptions:
                return "Multiple choice questions must have options"
            case .invalidOptionsCount:
                return "Multiple choice questions must have 2-5 options"
            case .correctAnswerNotInOptions:
                return "Correct answer must be one of the options"
            }
        }
    }
}

// MARK: - Analytics
extension Question {
    /// Calculate average response time
    func calculateAverageResponseTime(_ responses: [TimeInterval]) -> TimeInterval {
        guard !responses.isEmpty else { return 0 }
        return responses.reduce(0, +) / Double(responses.count)
    }
    
    /// Calculate success rate
    func calculateSuccessRate(_ attempts: Int, correct: Int) -> Float {
        guard attempts > 0 else { return 0 }
        return Float(correct) / Float(attempts)
    }
} 