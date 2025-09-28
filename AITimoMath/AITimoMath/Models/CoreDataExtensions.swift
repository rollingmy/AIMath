import Foundation
import CoreData

// MARK: - JSON Encoding/Decoding Helpers
extension Data {
    /// Decode JSON data to a Codable type
    func decodeJSON<T: Codable>(_ type: T.Type) -> T? {
        do {
            return try JSONDecoder().decode(type, from: self)
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}

extension Encodable {
    /// Encode to JSON data
    func encodeJSON() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            print("Error encoding JSON: \(error)")
            return nil
        }
    }
}

// MARK: - UserEntity Extensions
extension UserEntity {
    /// Convert Core Data entity to User model
    func toUser() -> User {
        // Decode completedLessons from JSON
        let completedLessons: [UUID]
        if let data = self.completedLessons {
            completedLessons = data.decodeJSON([UUID].self) ?? []
        } else {
            completedLessons = []
        }
        
        return User(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            avatar: self.avatar ?? "",
            gradeLevel: Int(self.gradeLevel),
            learningGoal: Int(self.learningGoal),
            difficultyLevel: User.DifficultyLevel(rawValue: self.difficultyLevel ?? "adaptive") ?? .adaptive,
            completedLessons: completedLessons,
            lastActiveAt: self.lastActiveAt ?? Date(),
            createdAt: self.createdAt ?? Date(),
            dailyGoal: Int(self.dailyGoal),
            dailyCompletedQuestions: Int(self.dailyCompletedQuestions)
        )
    }
    
    /// Update Core Data entity from User model
    func updateFromUser(_ user: User) {
        self.id = user.id
        self.name = user.name
        self.avatar = user.avatar
        self.gradeLevel = Int16(user.gradeLevel)
        self.learningGoal = Int16(user.learningGoal)
        self.difficultyLevel = user.difficultyLevel.rawValue
        self.completedLessons = user.completedLessons.encodeJSON()
        self.lastActiveAt = user.lastActiveAt
        self.createdAt = user.createdAt
        self.dailyGoal = Int16(user.dailyGoal)
        self.dailyCompletedQuestions = Int16(user.dailyCompletedQuestions)
    }
}

// MARK: - LessonEntity Extensions
extension LessonEntity {
    /// Convert Core Data entity to Lesson model
    func toLesson() -> Lesson {
        // Decode questions and responses from JSON
        let questions: [UUID]
        if let data = self.questions {
            questions = data.decodeJSON([UUID].self) ?? []
        } else {
            questions = []
        }
        
        let responses: [Lesson.QuestionResponse]
        if let data = self.responses {
            responses = data.decodeJSON([Lesson.QuestionResponse].self) ?? []
        } else {
            responses = []
        }
        
        return Lesson(
            id: self.id ?? UUID(),
            userId: self.userId ?? UUID(),
            subject: Lesson.Subject(rawValue: self.subject ?? "arithmetic") ?? .arithmetic,
            difficulty: Int(self.difficulty),
            questions: questions,
            responses: responses,
            accuracy: self.accuracy,
            responseTime: self.responseTime,
            startedAt: self.startedAt ?? Date(),
            completedAt: self.completedAt,
            status: Lesson.LessonStatus(rawValue: self.status ?? "not_started") ?? .notStarted
        )
    }
    
    /// Update Core Data entity from Lesson model
    func updateFromLesson(_ lesson: Lesson) {
        self.id = lesson.id
        self.userId = lesson.userId
        self.subject = lesson.subject.rawValue
        self.difficulty = Int16(lesson.difficulty)
        self.questions = lesson.questions.encodeJSON()
        self.responses = lesson.responses.encodeJSON()
        self.accuracy = lesson.accuracy
        self.responseTime = lesson.responseTime
        self.startedAt = lesson.startedAt
        self.completedAt = lesson.completedAt
        self.status = lesson.status.rawValue
    }
}

// MARK: - QuestionEntity Extensions
extension QuestionEntity {
    /// Convert Core Data entity to Question model
    func toQuestion() -> Question {
        let questionId = self.id ?? UUID()
        let questionSubject = Lesson.Subject(rawValue: self.subject ?? "arithmetic") ?? .arithmetic
        let questionDifficulty = Int(self.difficulty)
        let questionType = Question.QuestionType(rawValue: self.type ?? "mcq") ?? .multipleChoice
        let questionText = self.questionText ?? ""
        let questionCorrectAnswer = self.correctAnswer ?? ""
        
        // Create Question using the available initializer
        var question = Question(
            id: questionId,
            subject: questionSubject,
            difficulty: questionDifficulty,
            type: questionType,
            questionText: questionText,
            correctAnswer: questionCorrectAnswer
        )
        
        // Decode options and metadata from JSON
        if let data = self.options {
            question.options = data.decodeJSON([Question.QuestionOption].self) ?? []
        } else {
            question.options = []
        }
        
        question.hint = self.hint
        question.imageData = self.imageData
        
        // Handle metadata - convert from Data to [String: Any] using JSON decoding
        if let data = self.metadata {
            do {
                if let metadata = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    question.metadata = metadata
                } else {
                    question.metadata = [:]
                }
            } catch {
                print("Error decoding metadata: \(error)")
                question.metadata = [:]
            }
        } else {
            question.metadata = [:]
        }
        
        return question
    }
    
    /// Update Core Data entity from Question model
    func updateFromQuestion(_ question: Question) {
        self.id = question.id
        self.subject = question.subject.rawValue
        self.difficulty = Int16(question.difficulty)
        self.type = question.type.rawValue
        self.questionText = question.questionText
        self.options = question.options?.encodeJSON()
        self.correctAnswer = question.correctAnswer
        self.hint = question.hint
        self.imageData = question.imageData
        // Handle metadata - convert from [String: Any] to Data using JSON encoding
        if let metadata = question.metadata {
            do {
                self.metadata = try JSONSerialization.data(withJSONObject: metadata, options: [])
            } catch {
                print("Error encoding metadata: \(error)")
                self.metadata = nil
            }
        } else {
            self.metadata = nil
        }
    }
}