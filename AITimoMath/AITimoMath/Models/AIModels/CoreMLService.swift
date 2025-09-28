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
                print("Question recommender model not found")
            }
            
            // Student ability estimation model
            if let modelURL = Bundle.main.url(forResource: "AbilityEstimator", withExtension: "mlmodelc") {
                abilityEstimationModel = try await MLModel.load(contentsOf: modelURL)
            } else {
                print("Ability estimation model not found")
            }
            
            // Difficulty prediction model
            if let modelURL = Bundle.main.url(forResource: "DifficultyPredictor", withExtension: "mlmodelc") {
                difficultyPredictionModel = try await MLModel.load(contentsOf: modelURL)
            } else {
                print("Difficulty prediction model not found")
            }
            
            modelsLoaded = true
            print("CoreML models loaded successfully")
        } catch {
            print("Error loading CoreML models: \(error.localizedDescription)")
            modelsLoaded = false
        }
    }
    
    /// Wait for models to be loaded (useful for testing)
    public func waitForModelsToLoad() async {
        while !modelsLoaded {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
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
    ) throws -> Float {
        // Check if CoreML model is available
        guard modelsLoaded, let model = difficultyPredictionModel else {
            print("❌ DifficultyPredictor model not loaded (modelsLoaded: \(modelsLoaded))")
            throw CoreMLError.modelNotFound
        }
        
        do {
            // Convert features to MLFeatureProvider
            let inputFeatures = try createDifficultyInputFeatures(
                studentAbility: studentAbility,
                questionFeatures: questionFeatures
            )
            print("✅ Created input features for DifficultyPredictor")
            
            // Make prediction
            let prediction = try model.prediction(from: inputFeatures)
            print("✅ Got prediction from DifficultyPredictor")
            
            // Extract result - the model outputs a single difficulty value
            guard let difficultyValue = prediction.featureValue(for: "difficulty")?.doubleValue else {
                print("❌ Failed to extract difficulty from prediction")
                print("Available output features: \(prediction.featureNames)")
                throw CoreMLError.predictionFailed
            }
            
            print("✅ Predicted difficulty: \(difficultyValue)")
            return Float(difficultyValue)
            
        } catch {
            print("❌ Error in predictQuestionDifficulty: \(error)")
            throw error
        }
    }
    
    /// Estimate student ability from response pattern
    /// - Parameters:
    ///   - currentAbility: Current estimate of student ability
    ///   - responseHistory: History of student responses
    /// - Returns: Updated ability estimate
    public func estimateStudentAbility(
        currentAbility: Float,
        responseHistory: [Lesson.QuestionResponse]
    ) throws -> Float {
        // Check if CoreML model is available
        guard modelsLoaded, let model = abilityEstimationModel else {
            print("❌ AbilityEstimator model not loaded (modelsLoaded: \(modelsLoaded))")
            throw CoreMLError.modelNotFound
        }
        
        do {
            // Convert response history to MLFeatureProvider
            let inputFeatures = try createAbilityInputFeatures(
                currentAbility: currentAbility,
                responseHistory: responseHistory
            )
            print("✅ Created input features for AbilityEstimator")
            
            // Make prediction
            let prediction = try model.prediction(from: inputFeatures)
            print("✅ Got prediction from AbilityEstimator")
            
            // Extract result - the model outputs a single ability value
            guard let abilityValue = prediction.featureValue(for: "ability")?.doubleValue else {
                print("❌ Failed to extract ability from prediction")
                print("Available output features: \(prediction.featureNames)")
                throw CoreMLError.predictionFailed
            }
            
            print("✅ Estimated ability: \(abilityValue)")
            return Float(abilityValue)
            
        } catch {
            print("❌ Error in estimateStudentAbility: \(error)")
            throw error
        }
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
    ) throws -> [UUID] {
        // Check if CoreML model is available
        guard modelsLoaded, let model = questionRecommenderModel else {
            print("❌ QuestionRecommender model not loaded (modelsLoaded: \(modelsLoaded))")
            throw CoreMLError.modelNotFound
        }
        
        do {
            // Create feature vector for student profile
            let inputFeatures = try createRecommenderInputFeatures(studentProfile: studentProfile)
            print("✅ Created input features for QuestionRecommender")
            
            // Make prediction
            let prediction = try model.prediction(from: inputFeatures)
            print("✅ Got prediction from QuestionRecommender")
            
            // Extract result - the model outputs a single recommendation_score, not indices
            guard let recommendationScore = prediction.featureValue(for: "recommendation_score")?.doubleValue else {
                print("❌ Failed to extract recommendation_score from prediction")
                print("Available output features: \(prediction.featureNames)")
                throw CoreMLError.predictionFailed
            }
            
            print("✅ Recommendation score: \(recommendationScore)")
            
            // Since the model outputs a single score, we'll use it to select questions
            // For now, return the first 'count' questions as a simple implementation
            let selectedQuestions = Array(availableQuestions.prefix(count))
            return selectedQuestions.map { $0.id }
            
        } catch {
            print("❌ Error in recommendQuestions: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create input features for difficulty prediction
    private func createDifficultyInputFeatures(
        studentAbility: Float,
        questionFeatures: [String: Any]
    ) throws -> MLFeatureProvider {
        // Create a dictionary of features for the model
        var features: [String: MLFeatureValue] = [:]
        
        // Add required features for DifficultyPredictor model
        features["student_ability"] = MLFeatureValue(double: Double(studentAbility))
        features["subject_idx"] = MLFeatureValue(double: 0.0) // Default to arithmetic
        features["subject_pref"] = MLFeatureValue(double: 0.5) // Default preference
        features["irt_discrimination"] = MLFeatureValue(double: 1.0) // Default discrimination
        features["irt_difficulty"] = MLFeatureValue(double: 0.0) // Default difficulty
        features["irt_guessing"] = MLFeatureValue(double: 0.25) // Default guessing parameter
        features["is_open_ended"] = MLFeatureValue(double: 0.0) // Default to multiple choice
        features["question_length"] = MLFeatureValue(double: 50.0) // Default question length
        
        // Override with any provided question features
        for (key, value) in questionFeatures {
            if let doubleValue = value as? Double {
                features[key] = MLFeatureValue(double: doubleValue)
            } else if let floatValue = value as? Float {
                features[key] = MLFeatureValue(double: Double(floatValue))
            } else if let intValue = value as? Int {
                features[key] = MLFeatureValue(double: Double(intValue))
            }
        }
        
        return try MLDictionaryFeatureProvider(dictionary: features)
    }
    
    /// Create input features for ability estimation
    private func createAbilityInputFeatures(
        currentAbility: Float,
        responseHistory: [Lesson.QuestionResponse]
    ) throws -> MLFeatureProvider {
        // Create a dictionary of features for the model
        var features: [String: MLFeatureValue] = [:]
        
        // Add required features for AbilityEstimator model
        // Use the most recent response for single prediction
        if let lastResponse = responseHistory.last {
            features["is_correct"] = MLFeatureValue(double: lastResponse.isCorrect ? 1.0 : 0.0)
            features["response_time"] = MLFeatureValue(double: lastResponse.responseTime)
            features["difficulty"] = MLFeatureValue(double: 2.0) // Default difficulty
            features["subject_idx"] = MLFeatureValue(double: 0.0) // Default to arithmetic
        } else {
            // Default values if no response history
            features["is_correct"] = MLFeatureValue(double: 0.0)
            features["response_time"] = MLFeatureValue(double: 30.0)
            features["difficulty"] = MLFeatureValue(double: 2.0)
            features["subject_idx"] = MLFeatureValue(double: 0.0)
        }
        
        // Add subject preferences (default values)
        for i in 0..<5 {
            features["subject_pref_\(i)"] = MLFeatureValue(double: 0.2) // Equal preference
        }
        
        return try MLDictionaryFeatureProvider(dictionary: features)
    }
    
    /// Create input features for question recommender
    private func createRecommenderInputFeatures(
        studentProfile: [String: Any]
    ) throws -> MLFeatureProvider {
        // Create a dictionary of features for the model
        var features: [String: MLFeatureValue] = [:]
        
        // Add required features for QuestionRecommender model
        // Subject preferences (subject_pref_0 through subject_pref_4)
        for i in 0..<5 {
            if let pref = studentProfile["subject_pref_\(i)"] as? Double {
                features["subject_pref_\(i)"] = MLFeatureValue(double: pref)
            } else if let pref = studentProfile["subject_pref_\(i)"] as? Float {
                features["subject_pref_\(i)"] = MLFeatureValue(double: Double(pref))
            } else {
                features["subject_pref_\(i)"] = MLFeatureValue(double: 0.2) // Default equal preference
            }
        }
        
        // Subject accuracies (subject_acc_0 through subject_acc_4)
        for i in 0..<5 {
            if let acc = studentProfile["subject_acc_\(i)"] as? Double {
                features["subject_acc_\(i)"] = MLFeatureValue(double: acc)
            } else if let acc = studentProfile["subject_acc_\(i)"] as? Float {
                features["subject_acc_\(i)"] = MLFeatureValue(double: Double(acc))
            } else {
                features["subject_acc_\(i)"] = MLFeatureValue(double: 0.5) // Default 50% accuracy
            }
        }
        
        // Ability estimate
        if let ability = studentProfile["ability"] as? Double {
            features["ability_estimate"] = MLFeatureValue(double: ability)
        } else if let ability = studentProfile["ability"] as? Float {
            features["ability_estimate"] = MLFeatureValue(double: Double(ability))
        } else {
            features["ability_estimate"] = MLFeatureValue(double: 0.0) // Default ability
        }
        
        // Response count
        if let count = studentProfile["response_count"] as? Int {
            features["response_count"] = MLFeatureValue(double: Double(count))
        } else if let count = studentProfile["response_count"] as? Double {
            features["response_count"] = MLFeatureValue(double: count)
        } else {
            features["response_count"] = MLFeatureValue(double: 10.0) // Default response count
        }
        
        return try MLDictionaryFeatureProvider(dictionary: features)
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
    }
} 