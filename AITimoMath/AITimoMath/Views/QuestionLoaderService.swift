import Foundation

class QuestionLoaderService {
    private var allQuestions: [Question] = []
    private var isLoaded = false
    
    init() {
        loadQuestionsFromJSON()
    }
    
    private func loadQuestionsFromJSON() {
        // Try to load from Data subdirectory first, then root directory as fallback
        var url = Bundle.main.url(forResource: "timo_questions", withExtension: "json", subdirectory: "Data")
        
        if url == nil {
            // Fallback to root directory
            url = Bundle.main.url(forResource: "timo_questions", withExtension: "json")
        }
        
        guard let fileURL = url else {
            print("Error: Could not find timo_questions.json in bundle")
            
            // Create mock questions for development
            createMockQuestions()
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let questionData = try decoder.decode(QuestionData.self, from: data)
            
            // Convert JSON questions to our Question model
            self.allQuestions = questionData.questions.compactMap { jsonQuestion in
                convertJSONQuestionToQuestion(jsonQuestion)
            }
            self.isLoaded = true
            
            print("Successfully loaded \(allQuestions.count) questions from JSON")
        } catch {
            print("Error loading questions from JSON: \(error)")
            
            // Create mock questions if JSON parsing fails
            createMockQuestions()
        }
    }
    
    // Convert JSON question structure to our Question model
    private func convertJSONQuestionToQuestion(_ jsonQuestion: JSONQuestion) -> Question? {
        // Convert string ID to UUID
        let questionId: UUID
        if let uuid = UUID(uuidString: jsonQuestion.id) {
            questionId = uuid
        } else {
            // Generate UUID from string ID
            questionId = UUID()
        }
        
        // Convert subject string to enum
        let subject: Lesson.Subject
        switch jsonQuestion.subject {
        case "Logical Thinking":
            subject = .logicalThinking
        case "Arithmetic":
            subject = .arithmetic
        case "Number Theory":
            subject = .numberTheory
        case "Geometry":
            subject = .geometry
        case "Combinatorics":
            subject = .combinatorics
        default:
            return nil // Skip unknown subjects
        }
        
        // Convert difficulty string to integer
        let difficulty: Int
        switch jsonQuestion.difficulty {
        case "Easy":
            difficulty = 1
        case "Medium":
            difficulty = 2
        case "Hard":
            difficulty = 3
        case "Olympiad", "Olympiad Level":
            difficulty = 4
        default:
            difficulty = 1 // Default to Easy
        }
        
        // Convert question type
        let questionType: Question.QuestionType
        switch jsonQuestion.type {
        case "multiple-choice":
            questionType = .multipleChoice
        case "open-ended":
            questionType = .openEnded
        default:
            questionType = .multipleChoice
        }
        
        // Convert options - handle both string and object formats
        var options: [Question.QuestionOption]?
        if let jsonOptions = jsonQuestion.content.options {
            options = jsonOptions.map { jsonOption in
                if let type = jsonOption.type, type == "image", let value = jsonOption.value {
                    // Load image data from bundle
                    if let imageData = loadImageData(named: value) {
                        return Question.QuestionOption.image(imageData)
                    } else {
                        // Fallback to text if image not found
                        return Question.QuestionOption.text("Image: \(value)")
                    }
                } else if let value = jsonOption.value {
                    return Question.QuestionOption.text(value)
                } else {
                    return Question.QuestionOption.text("Unknown Option")
                }
            }
        }
        
        // Create metadata
        var metadata: [String: Any] = [:]
        if let parameters = jsonQuestion.parameters {
            metadata["eloRating"] = parameters.eloRating
            metadata["bkt"] = parameters.bkt
            metadata["irt"] = parameters.irt
        }
        if let jsonMetadata = jsonQuestion.metadata {
            metadata["tags"] = jsonMetadata.tags
            metadata["timeLimit"] = jsonMetadata.timeLimit
            metadata["pointsValue"] = jsonMetadata.pointsValue
        }
        
        // Create the Question object
        var question = Question(
            id: questionId,
            subject: subject,
            difficulty: difficulty,
            type: questionType,
            questionText: jsonQuestion.content.question,
            correctAnswer: jsonQuestion.content.correctAnswer
        )
        
        question.options = options
        question.hint = jsonQuestion.content.explanation
        question.metadata = metadata
        
        return question
    }
    
    // Helper function to load image data from bundle
    private func loadImageData(named imageName: String) -> Data? {
        guard let url = Bundle.main.url(forResource: imageName, withExtension: "png") else {
            print("Warning: Could not find image \(imageName).png in bundle")
            return nil
        }
        
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Error loading image \(imageName): \(error)")
            return nil
        }
    }
    
    // Create mock questions for development in case JSON loading fails
    private func createMockQuestions() {
        print("Creating mock questions")
        
        let subjects: [Lesson.Subject] = [.logicalThinking, .arithmetic, .numberTheory, .geometry, .combinatorics]
        let difficulties = [1, 2, 3, 4] // Easy, Medium, Hard, Olympiad
        
        var mockQuestions: [Question] = []
        
        for (subjectIndex, subject) in subjects.enumerated() {
            for (difficultyIndex, difficulty) in difficulties.enumerated() {
                for i in 1...5 {
                    let questionId = UUID()
                    let questionType: Question.QuestionType = i % 2 == 0 ? .multipleChoice : .openEnded
                    
                    // Create question text
                    let questionText = "Sample \(subject.rawValue.replacingOccurrences(of: "_", with: " ")) question #\(i) for difficulty level \(difficulty). What is the answer?"
                    
                    // Create correct answer
                    let correctAnswer = questionType == .multipleChoice ? "A" : "42"
                    
                    // Create options for multiple choice questions
                    var options: [Question.QuestionOption]?
                    if questionType == .multipleChoice {
                        options = [
                            .text("Option A"),
                            .text("Option B"),
                            .text("Option C"),
                            .text("Option D")
                        ]
                    }
                    
                    // Create question with proper structure
                    var question = Question(
                        id: questionId,
                        subject: subject,
                        difficulty: difficulty,
                        type: questionType,
                        questionText: questionText,
                        correctAnswer: correctAnswer
                    )
                    
                    // Add options if it's a multiple choice question
                    if let questionOptions = options {
                        question.options = questionOptions
                    }
                    
                    // Add hint
                    question.hint = "This is a hint for question #\(i) in \(subject.rawValue) at difficulty \(difficulty)."
                    
                    // Add metadata with AI parameters
                    let metadata: [String: Any] = [
                        "eloRating": 1000 + Double((subjectIndex * 100) + (difficultyIndex * 50) + (i * 10)),
                        "bkt": [
                            "pLearn": 0.4,
                            "pGuess": 0.25,
                            "pSlip": 0.1,
                            "pKnown": 0.5,
                            "pForget": 0.05
                        ],
                        "irt": [
                            "discrimination": 0.8,
                            "difficulty": Double(difficultyIndex) - 1.0,
                            "guessing": 0.25
                        ],
                        "tags": ["sample", subject.rawValue, "difficulty_\(difficulty)"],
                        "timeLimit": 60,
                        "pointsValue": 1
                    ]
                    question.metadata = metadata
                    
                    mockQuestions.append(question)
                }
            }
        }
        
        self.allQuestions = mockQuestions
        self.isLoaded = true
        
        print("Created \(mockQuestions.count) mock questions")
    }
    
    // Get questions filtered by subject and difficulty
    func getQuestions(subject: String? = nil, difficulty: String? = nil, count: Int = 5) -> [Question] {
        if !isLoaded {
            loadQuestionsFromJSON()
        }
        
        var filteredQuestions = allQuestions
        
        // Filter by subject if provided
        if let subjectString = subject {
            if let subjectEnum = Lesson.Subject(rawValue: subjectString) {
                filteredQuestions = filteredQuestions.filter { $0.subject == subjectEnum }
            } else {
                // Try to match by display name (normalize to lowercase with underscores)
                let displayName = subjectString
                    .replacingOccurrences(of: " ", with: "_")
                    .lowercased()
                if let subjectEnum = Lesson.Subject(rawValue: displayName) {
                    filteredQuestions = filteredQuestions.filter { $0.subject == subjectEnum }
                }
            }
        }
        
        // Filter by difficulty if provided
        if let difficultyString = difficulty {
            if difficultyString != "Adaptive" { // Only filter if not adaptive
                if let difficultyInt = Int(difficultyString) {
                    filteredQuestions = filteredQuestions.filter { $0.difficulty == difficultyInt }
                } else {
                    // Try to convert difficulty string to integer
                    let difficultyMap = ["Easy": 1, "Medium": 2, "Hard": 3, "Olympiad": 4]
                    if let difficultyInt = difficultyMap[difficultyString] {
                        filteredQuestions = filteredQuestions.filter { $0.difficulty == difficultyInt }
                    }
                }
            }
        }
        
        // Return all questions if we've filtered out everything
        if filteredQuestions.isEmpty && !allQuestions.isEmpty {
            filteredQuestions = allQuestions
        }
        
        // Randomize questions
        filteredQuestions.shuffle()
        
        // Limit to requested count
        return Array(filteredQuestions.prefix(min(count, filteredQuestions.count)))
    }
    
    // Helper method to get a question by ID
    func getQuestion(id: String) -> Question? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return allQuestions.first { $0.id == uuid }
    }
    
    // Get questions for a specific subject
    func getQuestionsForSubject(_ subject: String, count: Int = 5) -> [Question] {
        return getQuestions(subject: subject, count: count)
    }
    
    // Get questions at a specific difficulty level
    func getQuestionsAtDifficulty(_ difficulty: String, count: Int = 5) -> [Question] {
        return getQuestions(difficulty: difficulty, count: count)
    }
    
    // Get random questions (useful for assessments)
    func getRandomQuestions(count: Int = 5) -> [Question] {
        return getQuestions(count: count)
    }
}

// MARK: - JSON Structure
struct QuestionData: Codable {
    let version: String
    let lastUpdated: String
    let questions: [JSONQuestion]
}

struct JSONQuestion: Codable {
    let id: String
    let subject: String
    let type: String
    let difficulty: String
    let parameters: JSONParameters?
    let content: JSONContent
    let metadata: JSONMetadata?
}

struct JSONParameters: Codable {
    let eloRating: Int
    let bkt: JSONBKT
    let irt: JSONIRT
}

struct JSONBKT: Codable {
    let pLearn: Double
    let pGuess: Double
    let pSlip: Double
    let pKnown: Double
}

struct JSONIRT: Codable {
    let discrimination: Double
    let difficulty: Double
    let guessing: Double
}

struct JSONContent: Codable {
    let question: String
    let options: [JSONOption]?
    let correctAnswer: String
    let explanation: String?
    let imageData: String?
}

struct JSONOption: Codable {
    let type: String?
    let value: String?
    
    // Custom decoder to handle both string and object formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            // Simple string option
            self.type = "text"
            self.value = stringValue
        } else {
            // Object option with type and value
            let objectContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try objectContainer.decodeIfPresent(String.self, forKey: .type)
            self.value = try objectContainer.decodeIfPresent(String.self, forKey: .value)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
}

struct JSONMetadata: Codable {
    let tags: [String]
    let timeLimit: Int
    let pointsValue: Int
}