//
//  AITimoMathTests.swift
//  AITimoMathTests
//
//  Created by My Rolling on 10/3/25.
//

import Testing
@testable import AITimoMath
import Foundation

struct AITimoMathTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test("Performance and Mistakes reflect a 5-question session with 3 correct")
    func performanceAndMistakesUpdate() async throws {
        // Arrange: create a fresh user
        let user = User(name: "Test Student", avatar: "avatar-1", gradeLevel: 5, dailyGoal: 5)
        let performanceService = PerformanceService.shared
        let persistence = PersistenceController.shared

        // Create 5 mock questions and persist them so they are available by ID
        var sessionQuestions: [Question] = []
        for i in 0..<5 {
            var q = Question(
                id: UUID(),
                subject: .arithmetic,
                difficulty: 2,
                type: .multipleChoice,
                questionText: "Q\(i+1): What is 2+2?",
                correctAnswer: "A"
            )
            q.options = [.text("A"), .text("B"), .text("C"), .text("D")]
            try persistence.saveQuestion(q)
            sessionQuestions.append(q)
        }

        // Build responses: first 3 correct, last 2 incorrect
        var responses: [Lesson.QuestionResponse] = []
        for (index, q) in sessionQuestions.enumerated() {
            let isCorrect = index < 3
            responses.append(Lesson.QuestionResponse(
                questionId: q.id,
                isCorrect: isCorrect,
                responseTime: 2.0,
                answeredAt: Date(),
                selectedAnswer: isCorrect ? "A" : "B"
            ))
        }

        // Create and save completed lesson for Arithmetic
        var lesson = Lesson(userId: user.id, subject: .arithmetic)
        lesson.questions = sessionQuestions.map { $0.id }
        lesson.responses = responses
        lesson.status = .completed
        lesson.completedAt = Date()
        lesson.difficulty = 2
        lesson.accuracy = Float(3) / Float(5)
        lesson.responseTime = 2.0

        try await performanceService.saveLesson(lesson)

        // Act: compute subject performance
        let subjectPerf = try await performanceService.calculateSubjectPerformance(userId: user.id)
        let arithmetic = subjectPerf["Arithmetic"]

        // Assert accuracy is 60%
        #expect(arithmetic != nil)
        #expect(arithmetic?.totalQuestions == 5)
        #expect(arithmetic?.correctAnswers == 3)
        #expect(abs((arithmetic?.accuracy ?? 0) - 0.6) < 0.0001)

        // Act: load incorrect questions
        let incorrect = try await performanceService.loadIncorrectQuestions(userId: user.id)

        // Assert two incorrect questions are present
        #expect(incorrect.count == 2)
        let incorrectIds = Set(incorrect.map { $0.id })
        let expectedIncorrectIds = Set(sessionQuestions.suffix(2).map { $0.id })
        #expect(incorrectIds == expectedIncorrectIds)
    }

}
