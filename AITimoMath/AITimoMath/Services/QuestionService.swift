import Foundation
import SwiftUI

/// Service for loading and managing questions
class QuestionService {
    /// Shared instance for app-wide use
    static let shared = QuestionService()
    
    /// Cache of loaded questions
    private var questionCache: [String: Question] = [:]
    
    /// Private initializer for singleton
    private init() {}
    
    /// Load questions from the bundled JSON file
    /// - Returns: Array of questions
    func loadQuestions() async throws -> [Question] {
        // If we have cached questions, return them
        if !questionCache.isEmpty {
            return Array(questionCache.values)
        }
        
        // Otherwise, load from JSON
        guard let url = Bundle.main.url(forResource: "timo_questions", withExtension: "json") else {
            throw QuestionError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonQuestions = try decoder.decode(QuestionJSON.self, from: data)
            
            // Convert JSON questions to model questions
            var questions: [Question] = []
            for jsonQuestion in jsonQuestions.questions {
                if let question = try? convertJSONToQuestion(jsonQuestion) {
                    questions.append(question)
                    questionCache[question.id.uuidString] = question
                }
            }
            
            return questions
        } catch {
            throw QuestionError.decodingFailed(error)
        }
    }
    
    /// Get a question by ID
    /// - Parameter id: The question ID
    /// - Returns: The question if found
    func getQuestion(id: UUID) async throws -> Question? {
        // Check cache first
        if let question = questionCache[id.uuidString] {
            return question
        }
        
        // Otherwise, load all questions and check again
        _ = try await loadQuestions()
        return questionCache[id.uuidString]
    }
    
    /// Get questions by subject
    /// - Parameter subject: The subject to filter by
    /// - Returns: Array of questions for the subject
    func getQuestionsBySubject(_ subject: Lesson.Subject) async throws -> [Question] {
        let allQuestions = try await loadQuestions()
        return allQuestions.filter { $0.subject == subject }
    }
    
    /// Get questions by difficulty
    /// - Parameter difficulty: The difficulty level (1-4)
    /// - Returns: Array of questions with the specified difficulty
    func getQuestionsByDifficulty(_ difficulty: Int) async throws -> [Question] {
        let allQuestions = try await loadQuestions()
        return allQuestions.filter { $0.difficulty == difficulty }
    }
    
    /// Convert a JSON question to a Question model
    /// - Parameter jsonQuestion: The JSON question to convert
    /// - Returns: A Question model
    private func convertJSONToQuestion(_ jsonQuestion: QuestionJSON.Question) throws -> Question {
        // Convert subject string to Lesson.Subject
        guard let subject = convertSubject(jsonQuestion.subject) else {
            throw QuestionError.invalidSubject(jsonQuestion.subject)
        }
        
        // Convert difficulty string to Int
        let difficulty = convertDifficulty(jsonQuestion.difficulty)
        
        // Convert type string to QuestionType
        guard let type = convertType(jsonQuestion.type) else {
            throw QuestionError.invalidType(jsonQuestion.type)
        }
        
        // Create a UUID from the string ID
        let id = UUID(uuidString: jsonQuestion.id) ?? UUID()
        
        // Create the question
        var question = Question(
            id: id,
            subject: subject,
            difficulty: difficulty,
            type: type,
            questionText: jsonQuestion.content.question,
            correctAnswer: jsonQuestion.content.correctAnswer
        )
        
        // Set the hint
        question.hint = jsonQuestion.content.explanation
        
        // Convert options
        if let jsonOptions = jsonQuestion.content.options {
            // Process each option
            for option in jsonOptions {
                if let imageDataString = option.imageData, !imageDataString.isEmpty {
                    // If we have image data in the option, convert it
                    if let imageData = Data(base64Encoded: imageDataString) {
                        question.addImageOption(data: imageData)
                    }
                } else if let text = option.text {
                    // Otherwise, add as text option
                    question.addTextOption(text)
                }
            }
        }
        
        // Set question image data if available
        if let imageDataString = jsonQuestion.content.imageData, !imageDataString.isEmpty {
            if let imageData = Data(base64Encoded: imageDataString) {
                question.imageData = imageData
            }
        }
        
        return question
    }
    
    /// Convert a Question model to JSON format
    /// - Parameter question: The Question model to convert
    /// - Returns: A JSON representation of the question
    func convertQuestionToJSON(_ question: Question) -> [String: Any] {
        // Create the base JSON structure
        var json: [String: Any] = [
            "id": question.id.uuidString,
            "subject": convertSubjectToString(question.subject),
            "type": convertTypeToString(question.type),
            "difficulty": convertDifficultyToString(question.difficulty)
        ]
        
        // Add parameters
        json["parameters"] = [
            "eloRating": 1200,
            "bkt": [
                "pLearn": 0.35,
                "pGuess": 0.25,
                "pSlip": 0.15,
                "pKnown": 0.45
            ],
            "irt": [
                "discrimination": 0.9,
                "difficulty": 0.3,
                "guessing": 0.25
            ]
        ]
        
        // Add content
        var content: [String: Any] = [
            "question": question.questionText,
            "correctAnswer": question.correctAnswer
        ]
        
        // Add explanation if available
        if let hint = question.hint {
            content["explanation"] = hint
        } else {
            content["explanation"] = ""
        }
        
        // Convert options
        if let options = question.options, !options.isEmpty {
            var jsonOptions: [[String: Any]] = []
            
            for option in options {
                switch option {
                case .text(let text):
                    jsonOptions.append(["text": text])
                case .image(let data):
                    jsonOptions.append(["imageData": data.base64EncodedString()])
                }
            }
            
            content["options"] = jsonOptions
        }
        
        // Add image data if available
        if let imageData = question.imageData {
            content["imageData"] = imageData.base64EncodedString()
        }
        
        json["content"] = content
        
        // Add metadata
        json["metadata"] = [
            "tags": ["math", convertSubjectToString(question.subject).lowercased()],
            "timeLimit": 60,
            "pointsValue": 1
        ]
        
        return json
    }
    
    /// Save questions to JSON file
    /// - Parameter questions: The questions to save
    /// - Returns: Whether the save was successful
    func saveQuestions(_ questions: [Question]) -> Bool {
        // Create the JSON structure
        let json: [String: Any] = [
            "version": "1.0",
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "questions": questions.map { convertQuestionToJSON($0) }
        ]
        
        // Convert to data
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            return false
        }
        
        // Get the file URL
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("timo_questions.json") else {
            return false
        }
        
        // Write to file
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Error saving questions: \(error)")
            return false
        }
    }
    
    /// Convert a subject string to Lesson.Subject
    private func convertSubject(_ subjectString: String) -> Lesson.Subject? {
        switch subjectString.lowercased() {
        case "logical thinking":
            return .logicalThinking
        case "arithmetic":
            return .arithmetic
        case "number theory":
            return .numberTheory
        case "geometry":
            return .geometry
        case "combinatorics":
            return .combinatorics
        default:
            return nil
        }
    }
    
    /// Convert a difficulty string to Int
    private func convertDifficulty(_ difficultyString: String) -> Int {
        switch difficultyString {
        case "Easy":
            return 1
        case "Medium":
            return 2
        case "Hard":
            return 3
        case "Olympiad":
            return 4
        default:
            return 2 // Default to medium
        }
    }
    
    /// Convert a type string to QuestionType
    private func convertType(_ typeString: String) -> Question.QuestionType? {
        switch typeString.lowercased() {
        case "multiple-choice", "mcq":
            return .multipleChoice
        case "open-ended", "open_ended":
            return .openEnded
        default:
            return nil
        }
    }
    
    /// Convert a subject to string
    /// - Parameter subject: The subject to convert
    /// - Returns: A string representation of the subject
    private func convertSubjectToString(_ subject: Lesson.Subject) -> String {
        switch subject {
        case .logicalThinking:
            return "Logical Thinking"
        case .arithmetic:
            return "Arithmetic"
        case .numberTheory:
            return "Number Theory"
        case .geometry:
            return "Geometry"
        case .combinatorics:
            return "Combinatorics"
        }
    }
    
    /// Convert a question type to string
    /// - Parameter type: The question type to convert
    /// - Returns: A string representation of the type
    private func convertTypeToString(_ type: Question.QuestionType) -> String {
        switch type {
        case .multipleChoice:
            return "multiple-choice"
        case .openEnded:
            return "open-ended"
        }
    }
    
    /// Convert a difficulty level to string
    /// - Parameter difficulty: The difficulty level to convert
    /// - Returns: A string representation of the difficulty
    private func convertDifficultyToString(_ difficulty: Int) -> String {
        switch difficulty {
        case 1:
            return "Easy"
        case 2:
            return "Medium"
        case 3:
            return "Hard"
        case 4:
            return "Olympiad"
        default:
            return "Medium"
        }
    }
}

// MARK: - JSON Models
extension QuestionService {
    /// JSON structure for questions
    struct QuestionJSON: Codable {
        let version: String
        let lastUpdated: String
        let questions: [Question]
        
        struct Question: Codable {
            let id: String
            let subject: String
            let type: String
            let difficulty: String
            let parameters: Parameters
            let content: Content
            let metadata: Metadata
            
            struct Parameters: Codable {
                let eloRating: Int
                let bkt: BKT
                let irt: IRT
                
                struct BKT: Codable {
                    let pLearn: Double
                    let pGuess: Double
                    let pSlip: Double
                    let pKnown: Double
                }
                
                struct IRT: Codable {
                    let discrimination: Double
                    let difficulty: Double
                    let guessing: Double
                }
            }
            
            struct Content: Codable {
                let question: String
                let options: [OptionContent]?
                let correctAnswer: String
                let explanation: String
                let imageData: String?
                
                // Custom decoding to handle both string arrays and option objects
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    
                    question = try container.decode(String.self, forKey: .question)
                    correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
                    explanation = try container.decode(String.self, forKey: .explanation)
                    imageData = try container.decodeIfPresent(String.self, forKey: .imageData)
                    
                    // Try to decode options as an array of OptionContent first
                    if let optionObjects = try? container.decodeIfPresent([OptionContent].self, forKey: .options) {
                        options = optionObjects
                    } else if let stringOptions = try? container.decodeIfPresent([String].self, forKey: .options) {
                        // If that fails, try to decode as string array and convert
                        options = stringOptions.map { OptionContent(text: $0) }
                    } else {
                        options = nil
                    }
                }
                
                enum CodingKeys: String, CodingKey {
                    case question, options, correctAnswer, explanation, imageData
                }
            }
            
            struct OptionContent: Codable {
                let text: String?
                let imageData: String?
                
                init(text: String? = nil, imageData: String? = nil) {
                    self.text = text
                    self.imageData = imageData
                }
            }
            
            struct Metadata: Codable {
                let tags: [String]
                let timeLimit: Int
                let pointsValue: Int
            }
        }
    }
}

// MARK: - Error Handling
extension QuestionService {
    enum QuestionError: Error {
        case fileNotFound
        case decodingFailed(Error)
        case invalidSubject(String)
        case invalidType(String)
        case invalidDifficulty(String)
    }
} 