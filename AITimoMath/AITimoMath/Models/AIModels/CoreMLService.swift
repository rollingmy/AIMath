import Foundation
import CoreML
import UIKit

/// Service for managing CoreML models for AI predictions
public class CoreMLService {
    /// Shared instance for app-wide use
    public static let shared = CoreMLService()
    
    /// Manages model loading and unloading
    private let modelManager = CoreMLModelManager()
    
    /// Question recommendation model
    private var questionRecommenderModel: MLModel?
    
    /// Student ability estimation model
    private var abilityEstimationModel: MLModel?
    
    /// Difficulty prediction model
    private var difficultyPredictionModel: MLModel?
    
    /// Flag indicating if models are ready for use
    private var modelsLoaded = false
    
    /// Private initializer for singleton
    private init() {
        // Load models in the background to avoid blocking the UI
        Task {
            await loadModels()
        }
    }
    
    /// Load all required ML models
    public func loadModels() async {
        do {
            // Question recommender model
            if let modelURL = Bundle.main.url(forResource: "QuestionRecommender", withExtension: "mlmodelc") {
                questionRecommenderModel = try await MLModel.load(contentsOf: modelURL)
            } else {
                print("Question recommender model not found, using fallback logic")
            }
            
            // Student ability estimation model
            if let modelURL = Bundle.main.url(forResource: "AbilityEstimator", withExtension: "mlmodelc") {
                abilityEstimationModel = try await MLModel.load(contentsOf: modelURL)
            } else {
                print("Ability estimation model not found, using fallback logic")
            }
            
            // Difficulty prediction model
            if let modelURL = Bundle.main.url(forResource: "DifficultyPredictor", withExtension: "mlmodelc") {
                difficultyPredictionModel = try await MLModel.load(contentsOf: modelURL)
            } else {
                print("Difficulty prediction model not found, using fallback logic")
            }
            
            modelsLoaded = true
            print("CoreML models loaded successfully")
        } catch {
            print("Error loading CoreML models: \(error.localizedDescription)")
            print("Using fallback AI logic instead")
        }
    }
    
    /// Predict question difficulty for a student
    /// - Parameters:
    ///   - studentAbility: The student's ability level (IRT scale -3 to +3)
    ///   - questionFeatures: Features of the question
    /// - Returns: Predicted difficulty (0.0-1.0, higher = more difficult)
    public func predictQuestionDifficulty(
        studentAbility: Float,
        questionFeatures: [String: Any]
    ) -> Float {
        // Check if CoreML model is available
        guard modelsLoaded, let model = difficultyPredictionModel else {
            return fallbackDifficultyPrediction(studentAbility: studentAbility, questionFeatures: questionFeatures)
        }
        
        do {
            // Convert features to MLFeatureProvider
            let inputFeatures = try createDifficultyInputFeatures(
                studentAbility: studentAbility,
                questionFeatures: questionFeatures
            )
            
            // Make prediction
            let prediction = try model.prediction(from: inputFeatures)
            
            // Extract result (assuming model outputs a "difficulty" feature)
            if let difficultyValue = prediction.featureValue(for: "difficulty")?.doubleValue {
                return Float(difficultyValue)
            }
        } catch {
            print("Error making difficulty prediction: \(error.localizedDescription)")
        }
        
        // Fallback if prediction fails
        return fallbackDifficultyPrediction(studentAbility: studentAbility, questionFeatures: questionFeatures)
    }
    
    /// Estimate student ability from response pattern
    /// - Parameters:
    ///   - currentAbility: Current estimate of student ability
    ///   - responseHistory: History of student responses
    /// - Returns: Updated ability estimate
    public func estimateStudentAbility(
        currentAbility: Float,
        responseHistory: [Lesson.QuestionResponse]
    ) -> Float {
        // Check if CoreML model is available
        guard modelsLoaded, let model = abilityEstimationModel else {
            return fallbackAbilityEstimation(currentAbility: currentAbility, responseHistory: responseHistory)
        }
        
        do {
            // Convert response history to MLFeatureProvider
            let inputFeatures = try createAbilityInputFeatures(
                currentAbility: currentAbility,
                responseHistory: responseHistory
            )
            
            // Make prediction
            let prediction = try model.prediction(from: inputFeatures)
            
            // Extract result (assuming model outputs a "predictedAnswer" feature)
            if let predictedCorrect = prediction.featureValue(for: "predictedAnswer")?.doubleValue {
                return predictedCorrect > 0.5 ? 1.0 : 0.0 // Convert to Float (1.0 for true, 0.0 for false)
            }
        } catch {
            print("Error estimating student ability: \(error.localizedDescription)")
        }
        
        // Fallback if prediction fails
        return fallbackAbilityEstimation(currentAbility: currentAbility, responseHistory: responseHistory)
    }
    
    /// Recommend questions based on student profile
    /// - Parameters:
    ///   - studentProfile: The student's learning profile
    ///   - availableQuestions: Pool of available questions to choose from
    ///   - count: Number of questions to recommend
    /// - Returns: Array of recommended question IDs
    public func recommendQuestions(
        studentProfile: [String: Any],
        availableQuestions: [Question],
        count: Int
    ) -> [UUID] {
        // Check if CoreML model is available
        guard modelsLoaded, let model = questionRecommenderModel else {
            return fallbackQuestionRecommendation(
                studentProfile: studentProfile,
                availableQuestions: availableQuestions,
                count: count
            )
        }
        
        var recommendedQuestions: [UUID] = []
        
        do {
            // Create feature vector for student profile
            let inputFeatures = try createRecommenderInputFeatures(studentProfile: studentProfile)
            
            // Make prediction
            let prediction = try model.prediction(from: inputFeatures)
            
            // Extract result (assuming model outputs "recommendedQuestionIndices" as a multi-array)
            if let indices = prediction.featureValue(for: "recommendedQuestionIndices")?.multiArrayValue {
                // Convert multi-array indices to question IDs
                for i in 0..<min(Int(indices.count), count) {
                    if let index = try? indices[i].intValue, 
                       index >= 0 && index < availableQuestions.count {
                        recommendedQuestions.append(availableQuestions[index].id)
                    }
                }
            }
        } catch {
            print("Error recommending questions: \(error.localizedDescription)")
        }
        
        // If we don't have enough recommendations, use fallback
        if recommendedQuestions.count < count {
            let fallbackRecommendations = fallbackQuestionRecommendation(
                studentProfile: studentProfile,
                availableQuestions: availableQuestions.filter { !recommendedQuestions.contains($0.id) },
                count: count - recommendedQuestions.count
            )
            recommendedQuestions.append(contentsOf: fallbackRecommendations)
        }
        
        return recommendedQuestions
    }
    
    // MARK: - Helper Methods
    
    /// Create input features for difficulty prediction
    private func createDifficultyInputFeatures(
        studentAbility: Float,
        questionFeatures: [String: Any]
    ) throws -> MLFeatureProvider {
        // In a real implementation, this would create MLMultiArray features
        // based on the model's expected input format
        
        // For this prototype, we'll throw an error to trigger the fallback
        throw CoreMLError.featureCreationFailed
    }
    
    /// Create input features for ability estimation
    private func createAbilityInputFeatures(
        currentAbility: Float,
        responseHistory: [Lesson.QuestionResponse]
    ) throws -> MLFeatureProvider {
        // In a real implementation, this would create MLMultiArray features
        // based on the model's expected input format
        
        // For this prototype, we'll throw an error to trigger the fallback
        throw CoreMLError.featureCreationFailed
    }
    
    /// Create input features for question recommender
    private func createRecommenderInputFeatures(
        studentProfile: [String: Any]
    ) throws -> MLFeatureProvider {
        // In a real implementation, this would create MLMultiArray features
        // based on the model's expected input format
        
        // For this prototype, we'll throw an error to trigger the fallback
        throw CoreMLError.featureCreationFailed
    }
    
    // MARK: - Fallback Methods
    
    /// Fallback difficulty prediction if CoreML isn't available
    private func fallbackDifficultyPrediction(
        studentAbility: Float,
        questionFeatures: [String: Any]
    ) -> Float {
        // Extract question difficulty if available
        if let difficulty = questionFeatures["difficulty"] as? Float {
            return difficulty
        }
        
        // For fixed difficulty levels (1-4), convert to 0-1 scale
        if let difficultyLevel = questionFeatures["difficultyLevel"] as? Int {
            return Float(difficultyLevel) / 4.0
        }
        
        // Use IRT model as fallback
        let irtModel = IRTModel()
        let params = IRTModel.Parameters(
            discrimination: 1.0,
            difficulty: 0.0,
            guessing: 0.25
        )
        
        // Convert to probability (higher probability = lower difficulty)
        let probability = irtModel.probabilityOfCorrectAnswer(
            ability: studentAbility,
            parameters: params
        )
        
        // Invert the probability to get difficulty (higher difficulty = harder)
        return 1.0 - probability
    }
    
    /// Fallback ability estimation if CoreML isn't available
    private func fallbackAbilityEstimation(
        currentAbility: Float,
        responseHistory: [Lesson.QuestionResponse]
    ) -> Float {
        // If no responses, keep current ability
        guard !responseHistory.isEmpty else {
            return currentAbility
        }
        
        // Calculate proportion of correct answers
        let totalResponses = responseHistory.count
        let correctResponses = responseHistory.filter { $0.isCorrect }.count
        let correctRatio = Float(correctResponses) / Float(totalResponses)
        
        // Apply simplified ability update
        // If mostly correct, increase ability
        // If mostly incorrect, decrease ability
        if correctRatio > 0.7 {
            return min(3.0, currentAbility + 0.2)
        } else if correctRatio < 0.4 {
            return max(-3.0, currentAbility - 0.2)
        } else {
            // Small adjustment based on ratio
            let adjustment = (correctRatio - 0.5) * 0.3
            return min(3.0, max(-3.0, currentAbility + adjustment))
        }
    }
    
    /// Fallback question recommendation if CoreML isn't available
    private func fallbackQuestionRecommendation(
        studentProfile: [String: Any],
        availableQuestions: [Question],
        count: Int
    ) -> [UUID] {
        // Extract student ability if available
        let ability: Float = studentProfile["ability"] as? Float ?? 0.0
        
        // Extract weak subjects if available
        let weakSubjects = studentProfile["weakSubjects"] as? [String] ?? []
        
        // Sort questions by matching to student ability
        let sortedQuestions = availableQuestions.sorted { q1, q2 in
            // Prioritize questions from weak subjects
            let q1InWeakSubject = weakSubjects.contains(q1.subject.rawValue)
            let q2InWeakSubject = weakSubjects.contains(q2.subject.rawValue)
            
            if q1InWeakSubject != q2InWeakSubject {
                return q1InWeakSubject
            }
            
            // Then prioritize by appropriate difficulty
            let q1Difficulty = Float(q1.difficulty)
            let q2Difficulty = Float(q2.difficulty)
            let targetDifficulty = ability + 0.5 // Slightly challenging
            
            let q1Distance = abs(q1Difficulty - targetDifficulty)
            let q2Distance = abs(q2Difficulty - targetDifficulty)
            
            return q1Distance < q2Distance
        }
        
        // Return the top N questions
        return Array(sortedQuestions.prefix(count).map { $0.id })
    }
}

// MARK: - CoreML Model Manager

/// Manages loading and unloading of CoreML models
class CoreMLModelManager {
    /// Dictionary of loaded models
    private var loadedModels: [String: MLModel] = [:]
    
    /// Load a model by name
    /// - Parameter name: The model name (without extension)
    /// - Returns: The loaded model, or nil if not found
    func loadModel(named name: String) async throws -> MLModel? {
        // Check if already loaded
        if let model = loadedModels[name] {
            return model
        }
        
        // Try to load from bundle
        if let modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            let model = try await MLModel.load(contentsOf: modelURL)
            loadedModels[name] = model
            return model
        }
        
        return nil
    }
    
    /// Unload a model to free memory
    /// - Parameter name: The model name to unload
    func unloadModel(named name: String) {
        loadedModels.removeValue(forKey: name)
    }
    
    /// Unload all models
    func unloadAllModels() {
        loadedModels.removeAll()
    }
}

// MARK: - Error Handling

extension CoreMLService {
    enum CoreMLError: Error {
        case modelNotFound
        case predictionFailed
        case featureCreationFailed
    }
} 