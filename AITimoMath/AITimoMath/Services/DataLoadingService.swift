import Foundation

/// Service for loading data from json files in the app bundle
class DataLoadingService {
    /// Shared instance
    static let shared = DataLoadingService()
    
    /// Errors that can occur during data loading
    enum DataLoadingError: Error {
        case fileNotFound
        case dataCorrupted
        case decodingFailed(Error)
    }
    
    /// Load the TIMO question bank from the json file
    func loadQuestionBank() -> Result<[Question], DataLoadingError> {
        // Look for the file in the app bundle
        guard let url = Bundle.main.url(forResource: "timo_questions", withExtension: "json") else {
            return .failure(.fileNotFound)
        }
        
        do {
            // Read the data from the file
            let data = try Data(contentsOf: url)
            
            // Decode the JSON into Question objects
            let decoder = JSONDecoder()
            
            // Custom date decoding strategy if needed
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            // Decode the array of questions
            let questions = try decoder.decode([Question].self, from: data)
            return .success(questions)
        } catch let dataError {
            return .failure(.dataCorrupted)
        } catch let decodingError {
            return .failure(.decodingFailed(decodingError))
        }
    }
    
    /// Load the data from the json file in the Data directory
    func loadQuestionBank(completion: @escaping (Result<[Question], DataLoadingError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.loadQuestionBank()
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

// Extension to QuestionService to use DataLoadingService
extension QuestionService {
    /// Load all questions from the question bank
    func loadQuestionBank(completion: @escaping (Result<[Question], DataLoadingService.DataLoadingError>) -> Void) {
        DataLoadingService.shared.loadQuestionBank(completion: completion)
    }
    
    /// Load questions for a given difficulty level
    func loadQuestionsForDifficulty(_ difficulty: Int, completion: @escaping (Result<[Question], DataLoadingService.DataLoadingError>) -> Void) {
        DataLoadingService.shared.loadQuestionBank { result in
            switch result {
            case .success(let allQuestions):
                let filteredQuestions = allQuestions.filter { $0.difficulty == difficulty }
                completion(.success(filteredQuestions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Load questions for a given subject
    func loadQuestionsForSubject(_ subject: Lesson.Subject, completion: @escaping (Result<[Question], DataLoadingService.DataLoadingError>) -> Void) {
        DataLoadingService.shared.loadQuestionBank { result in
            switch result {
            case .success(let allQuestions):
                let filteredQuestions = allQuestions.filter { $0.subject == subject }
                completion(.success(filteredQuestions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Load questions for assessment based on grade level
    func loadAssessmentQuestions(gradeLevel: Int, count: Int = 5, completion: @escaping (Result<[Question], DataLoadingService.DataLoadingError>) -> Void) {
        DataLoadingService.shared.loadQuestionBank { result in
            switch result {
            case .success(let allQuestions):
                // Filter questions appropriate for the grade level
                // For grades 1-3, use difficulties 1-2
                // For grades 4-6, use difficulties 2-3
                let appropriateDifficulties: [Int]
                if gradeLevel <= 3 {
                    appropriateDifficulties = [1, 2]
                } else {
                    appropriateDifficulties = [2, 3]
                }
                
                // Filter and randomize
                let filteredQuestions = allQuestions
                    .filter { appropriateDifficulties.contains($0.difficulty) }
                    .filter { $0.type == .multipleChoice } // Only use MCQs for assessment
                    .shuffled()
                
                // Take the first 'count' questions or all if fewer
                let assessmentQuestions = Array(filteredQuestions.prefix(count))
                completion(.success(assessmentQuestions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 