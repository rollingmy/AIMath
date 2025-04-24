import Foundation
import CloudKit
import SwiftUI

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
    public var options: [QuestionOption]?
    
    /// Correct answer
    public let correctAnswer: String
    
    /// Optional hint for students
    public var hint: String?
    
    /// Optional image data for visual questions (stored locally)
    public var imageData: Data?
    
    /// Optional metadata dictionary for storing additional information
    public var metadata: [String: Any]?
    
    /// Computed property to convert imageData to UIImage
    public var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, subject, difficulty, type, questionText, options, correctAnswer, hint, imageData, metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.subject = try container.decode(Lesson.Subject.self, forKey: .subject)
        self.difficulty = try container.decode(Int.self, forKey: .difficulty)
        self.type = try container.decode(QuestionType.self, forKey: .type)
        self.questionText = try container.decode(String.self, forKey: .questionText)
        self.options = try container.decodeIfPresent([QuestionOption].self, forKey: .options)
        self.correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        self.hint = try container.decodeIfPresent(String.self, forKey: .hint)
        self.imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        
        // Decode metadata as Data and convert to dictionary
        if let metadataData = try container.decodeIfPresent(Data.self, forKey: .metadata) {
            self.metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]
        } else {
            self.metadata = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(subject, forKey: .subject)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(type, forKey: .type)
        try container.encode(questionText, forKey: .questionText)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encode(correctAnswer, forKey: .correctAnswer)
        try container.encodeIfPresent(hint, forKey: .hint)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        
        // Encode metadata to Data if present
        if let metadata = metadata {
            let metadataData = try JSONSerialization.data(withJSONObject: metadata)
            try container.encode(metadataData, forKey: .metadata)
        }
    }
}

// MARK: - Supporting Types
extension Question {
    public enum QuestionType: String, Codable {
        case multipleChoice = "mcq"
        case openEnded = "open_ended"
    }
    
    /// Represents an option that can be either text or image
    public enum QuestionOption: Codable, Equatable {
        case text(String)
        case image(Data)
        
        // Custom coding keys for encoding/decoding
        private enum CodingKeys: String, CodingKey {
            case type, value
        }
        
        // Custom type identifiers
        private enum OptionType: String, Codable {
            case text, image
        }
        
        // Custom encoding
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .text(let string):
                try container.encode(OptionType.text, forKey: .type)
                try container.encode(string, forKey: .value)
            case .image(let data):
                try container.encode(OptionType.image, forKey: .type)
                try container.encode(data, forKey: .value)
            }
        }
        
        // Custom decoding
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(OptionType.self, forKey: .type)
            
            switch type {
            case .text:
                let value = try container.decode(String.self, forKey: .value)
                self = .text(value)
            case .image:
                let value = try container.decode(Data.self, forKey: .value)
                self = .image(value)
            }
        }
        
        // Helper to get text value if available
        public var textValue: String? {
            if case .text(let value) = self {
                return value
            }
            return nil
        }
        
        // Helper to get image data if available
        public var imageData: Data? {
            if case .image(let data) = self {
                return data
            }
            return nil
        }
        
        // Helper to get UIImage if available
        public var image: UIImage? {
            if let data = imageData {
                return UIImage(data: data)
            }
            return nil
        }
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
        self.options = nil
        self.hint = nil
        self.imageData = nil
    }
    
    /// Initialization with custom ID
    public init(
        id: UUID,
        subject: Lesson.Subject,
        difficulty: Int,
        type: QuestionType,
        questionText: String,
        correctAnswer: String
    ) {
        self.id = id
        self.subject = subject
        self.difficulty = difficulty
        self.type = type
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.options = nil
        self.hint = nil
        self.imageData = nil
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
        record["correctAnswer"] = correctAnswer
        record["hint"] = hint
        
        // Store options as encoded data
        if let options = options {
            do {
                let optionsData = try JSONEncoder().encode(options)
                record["optionsData"] = optionsData
            } catch {
                print("Error encoding options: \(error)")
            }
        }
        
        // Store image data as CKAsset if available
        if let imageData = imageData {
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString)
            
            do {
                try imageData.write(to: tempFileURL)
                let asset = CKAsset(fileURL: tempFileURL)
                record["imageData"] = asset
            } catch {
                print("Error creating CKAsset: \(error)")
            }
        }
        
        // Store metadata as JSON data
        if let metadata = metadata {
            do {
                // Convert metadata to JSON data
                let jsonData = try JSONSerialization.data(withJSONObject: metadata)
                record["metadata"] = jsonData
            } catch {
                print("Error encoding metadata: \(error)")
            }
        }
        
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
        self.hint = record["hint"] as? String
        
        // Extract options data
        if let optionsData = record["optionsData"] as? Data {
            self.options = try? JSONDecoder().decode([QuestionOption].self, from: optionsData)
        } else if let legacyOptions = record["options"] as? [String] {
            // Handle legacy string options
            self.options = legacyOptions.map { .text($0) }
        } else {
            self.options = nil
        }
        
        // Extract image data from CKAsset
        if let asset = record["imageData"] as? CKAsset, let fileURL = asset.fileURL {
            self.imageData = try? Data(contentsOf: fileURL)
        } else {
            self.imageData = nil
        }
        
        // Extract metadata if available
        if let metadataData = record["metadata"] as? Data {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
                    self.metadata = jsonObject
                }
            } catch {
                print("Error decoding metadata: \(error)")
                self.metadata = nil
            }
        } else {
            self.metadata = nil
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
            
            // Check if correct answer is in options
            let textOptions = options.compactMap { option -> String? in
                if case .text(let text) = option {
                    return text
                }
                return nil
            }
            
            if !textOptions.isEmpty && !textOptions.contains(correctAnswer) {
                throw ValidationError.correctAnswerNotInOptions
            }
        }
        
        // Image data validation (optional)
        if let imageData = imageData, imageData.count > 5 * 1024 * 1024 {
            throw ValidationError.imageTooLarge
        }
        
        // Option image validation
        if let options = options {
            for option in options {
                if case .image(let data) = option, data.count > 5 * 1024 * 1024 {
                    throw ValidationError.optionImageTooLarge
                }
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
        case imageTooLarge
        case optionImageTooLarge
        
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
            case .imageTooLarge:
                return "Image size cannot exceed 5MB"
            case .optionImageTooLarge:
                return "Option image size cannot exceed 5MB"
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

// MARK: - Image Handling
extension Question {
    /// Set image from UIImage
    mutating func setImage(_ image: UIImage, compressionQuality: CGFloat = 0.7) {
        if let compressedData = image.jpegData(compressionQuality: compressionQuality) {
            self.imageData = compressedData
        }
    }
    
    /// Set image from local file URL
    mutating func setImageFromFile(url: URL) throws {
        self.imageData = try Data(contentsOf: url)
    }
    
    /// Set image from Base64 string
    mutating func setImageFromBase64(_ base64String: String) {
        if let data = Data(base64Encoded: base64String) {
            self.imageData = data
        }
    }
    
    /// Add a text option
    mutating func addTextOption(_ text: String) {
        if options == nil {
            options = []
        }
        options?.append(.text(text))
    }
    
    /// Add an image option
    mutating func addImageOption(_ image: UIImage, compressionQuality: CGFloat = 0.7) {
        if options == nil {
            options = []
        }
        if let compressedData = image.jpegData(compressionQuality: compressionQuality) {
            options?.append(.image(compressedData))
        }
    }
    
    /// Add an image option from data
    mutating func addImageOption(data: Data) {
        if options == nil {
            options = []
        }
        options?.append(.image(data))
    }
    
    /// Convert legacy string options to new format
    mutating func convertLegacyOptions(_ stringOptions: [String]) {
        self.options = stringOptions.map { .text($0) }
    }
}

// MARK: - Equatable
extension Question {
    public static func == (lhs: Question, rhs: Question) -> Bool {
        // Compare all properties except metadata, which isn't Equatable
        return lhs.id == rhs.id &&
               lhs.subject == rhs.subject &&
               lhs.difficulty == rhs.difficulty &&
               lhs.type == rhs.type &&
               lhs.questionText == rhs.questionText &&
               lhs.options == rhs.options &&
               lhs.correctAnswer == rhs.correctAnswer &&
               lhs.hint == rhs.hint &&
               lhs.imageData == rhs.imageData
        // Note: metadata is intentionally excluded as [String: Any] doesn't conform to Equatable
    }
} 