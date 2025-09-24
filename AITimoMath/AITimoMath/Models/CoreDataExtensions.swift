import Foundation
import CoreData

// MARK: - UserEntity Extensions
extension UserEntity {
    /// Convert Core Data entity to User model
    func toUser() -> User {
        return User(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            avatar: self.avatar ?? "",
            gradeLevel: Int(self.gradeLevel),
            learningGoal: Int(self.learningGoal),
            difficultyLevel: User.DifficultyLevel(rawValue: self.difficultyLevel ?? "adaptive") ?? .adaptive,
            completedLessons: self.completedLessons as? [UUID] ?? [],
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
        self.completedLessons = user.completedLessons as NSObject
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
        return Lesson(
            id: self.id ?? UUID(),
            userId: self.userId ?? UUID(),
            subject: Lesson.Subject(rawValue: self.subject ?? "arithmetic") ?? .arithmetic,
            difficulty: Int(self.difficulty),
            questions: self.questions as? [UUID] ?? [],
            responses: self.responses as? [Lesson.QuestionResponse] ?? [],
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
        self.questions = lesson.questions as NSObject
        self.responses = lesson.responses as NSObject
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
        
        // Set additional properties
        question.options = self.options as? [Question.QuestionOption] ?? []
        question.hint = self.hint
        question.imageData = self.imageData
        question.metadata = self.metadata as? [String: Any] ?? [:]
        
        return question
    }
    
    /// Update Core Data entity from Question model
    func updateFromQuestion(_ question: Question) {
        self.id = question.id
        self.subject = question.subject.rawValue
        self.difficulty = Int16(question.difficulty)
        self.type = question.type.rawValue
        self.questionText = question.questionText
        self.options = question.options as NSObject?
        self.correctAnswer = question.correctAnswer
        self.hint = question.hint
        self.imageData = question.imageData
        self.metadata = question.metadata as NSObject?
    }
}
