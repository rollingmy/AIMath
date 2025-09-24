import Foundation
import CoreData

/// Service for managing user performance data and lesson history
public class PerformanceService {
    /// Shared instance for app-wide use
    public static let shared = PerformanceService()
    
    /// Core Data persistence controller
    private let persistenceController = PersistenceController.shared
    
    /// Private initializer for singleton
    private init() {}
    
    // MARK: - Save
    /// Save a lesson record to Core Data
    /// - Parameter lesson: The completed or in-progress lesson to save
    public func saveLesson(_ lesson: Lesson) async throws {
        try persistenceController.saveLesson(lesson)
    }
    
    /// Load user's lesson history
    /// - Parameter userId: The user's ID
    /// - Returns: Array of completed lessons
    public func loadUserLessonHistory(userId: UUID) async throws -> [Lesson] {
        return try persistenceController.fetchCompletedLessons(userId: userId)
    }
    
    /// Load incorrect questions from user's lesson history
    /// - Parameter userId: The user's ID
    /// - Returns: Array of questions the user got wrong
    public func loadIncorrectQuestions(userId: UUID) async throws -> [Question] {
        // First, get all completed lessons
        let lessons = try await loadUserLessonHistory(userId: userId)
        
        // Get all question IDs that were answered incorrectly
        var incorrectQuestionIds: Set<UUID> = []
        
        for lesson in lessons {
            for response in lesson.responses {
                if !response.isCorrect {
                    incorrectQuestionIds.insert(response.questionId)
                }
            }
        }
        
        // Load the actual question data for incorrect questions
        var incorrectQuestions: [Question] = []
        
        for questionId in incorrectQuestionIds {
            if let question = try? persistenceController.fetchQuestion(id: questionId) {
                incorrectQuestions.append(question)
            }
        }
        
        return incorrectQuestions
    }
    
    /// Calculate performance data for each subject
    /// - Parameter userId: The user's ID
    /// - Returns: Dictionary of subject performance data
    public func calculateSubjectPerformance(userId: UUID) async throws -> [String: SubjectPerformanceData] {
        let lessons = try await loadUserLessonHistory(userId: userId)
        
        var subjectData: [String: SubjectPerformanceData] = [:]
        
        // Initialize data for all subjects
        let allSubjects = [
            "Logical Thinking",
            "Arithmetic", 
            "Number Theory",
            "Geometry",
            "Combinatorics"
        ]
        
        for subject in allSubjects {
            subjectData[subject] = SubjectPerformanceData(
                subject: subject,
                totalQuestions: 0,
                correctAnswers: 0,
                accuracy: 0.0,
                averageResponseTime: 0.0,
                lessonsCompleted: 0
            )
        }
        
        // Calculate performance for each lesson
        for lesson in lessons {
            let subjectName = getSubjectDisplayName(lesson.subject)
            
            guard var data = subjectData[subjectName] else { continue }
            
            data.lessonsCompleted += 1
            data.totalQuestions += lesson.responses.count
            data.correctAnswers += lesson.responses.filter { $0.isCorrect }.count
            
            // Calculate accuracy
            if data.totalQuestions > 0 {
                data.accuracy = Double(data.correctAnswers) / Double(data.totalQuestions)
            }
            
            // Calculate average response time
            let totalResponseTime = lesson.responses.map { $0.responseTime }.reduce(0, +)
            if !lesson.responses.isEmpty {
                data.averageResponseTime = totalResponseTime / Double(lesson.responses.count)
            }
            
            subjectData[subjectName] = data
        }
        
        return subjectData
    }
    
    /// Get user's weak areas based on performance data
    /// - Parameter userId: The user's ID
    /// - Returns: Array of identified weak areas
    public func identifyWeakAreas(userId: UUID) async throws -> [String] {
        let subjectPerformance = try await calculateSubjectPerformance(userId: userId)
        var weakAreas: [String] = []
        
        // Sort subjects by accuracy (lowest first)
        let sortedSubjects = subjectPerformance.values.sorted { $0.accuracy < $1.accuracy }
        
        // Identify weak areas based on lowest performing subjects
        for subjectData in sortedSubjects.prefix(2) {
            if subjectData.accuracy < 0.7 { // Less than 70% accuracy
                let weakArea = getWeakAreaForSubject(subjectData.subject)
                weakAreas.append(weakArea)
            }
        }
        
        // Add general weak areas if overall performance is low
        let overallAccuracy = subjectPerformance.values.map { $0.accuracy }.reduce(0, +) / Double(subjectPerformance.count)
        if overallAccuracy < 0.6 {
            weakAreas.append("Word Problem Comprehension")
            weakAreas.append("Multi-Step Problems")
        }
        
        return Array(Set(weakAreas)) // Remove duplicates
    }
    
    /// Helper function to get display name for subject
    private func getSubjectDisplayName(_ subject: Lesson.Subject) -> String {
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
    
    /// Helper function to get weak area description for subject
    private func getWeakAreaForSubject(_ subject: String) -> String {
        switch subject {
        case "Logical Thinking":
            return "Pattern Recognition and Logical Inference"
        case "Arithmetic":
            return "Fractions and Division"
        case "Number Theory":
            return "Prime Factorization and LCM/GCD"
        case "Geometry":
            return "Area Calculation and Spatial Reasoning"
        case "Combinatorics":
            return "Probability and Counting Principles"
        default:
            return "Problem Solving in \(subject)"
        }
    }
}

/// Data structure for subject performance
public struct SubjectPerformanceData {
    public let subject: String
    public var totalQuestions: Int
    public var correctAnswers: Int
    public var accuracy: Double
    public var averageResponseTime: TimeInterval
    public var lessonsCompleted: Int
    
    public init(subject: String, totalQuestions: Int, correctAnswers: Int, accuracy: Double, averageResponseTime: TimeInterval, lessonsCompleted: Int) {
        self.subject = subject
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.accuracy = accuracy
        self.averageResponseTime = averageResponseTime
        self.lessonsCompleted = lessonsCompleted
    }
} 