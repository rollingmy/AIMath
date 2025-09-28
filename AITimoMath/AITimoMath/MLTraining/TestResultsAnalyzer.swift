import Foundation

/// Analyzes and reports on AI model test results
/// Provides detailed analysis, trends, and recommendations
class TestResultsAnalyzer {
    
    // MARK: - Analysis Results
    
    struct AnalysisResult {
        let overallScore: Float
        let deploymentReadiness: DeploymentReadiness
        let modelPerformance: [String: ModelPerformance]
        let recommendations: [Recommendation]
        let trends: [Trend]
        let summary: String
    }
    
    struct ModelPerformance {
        let accuracy: Float
        let precision: Float
        let recall: Float
        let f1Score: Float
        let testCases: Int
        let passed: Bool
        let performanceLevel: PerformanceLevel
        let issues: [String]
        let strengths: [String]
    }
    
    enum PerformanceLevel {
        case excellent    // 95%+
        case good         // 85-94%
        case acceptable   // 75-84%
        case poor         // 60-74%
        case critical     // <60%
    }
    
    enum DeploymentReadiness {
        case ready        // All models pass, high confidence
        case conditional  // Most models pass, some concerns
        case notReady     // Significant issues found
        case critical     // Major failures detected
    }
    
    struct Recommendation {
        let priority: Priority
        let category: Category
        let title: String
        let description: String
        let actionItems: [String]
    }
    
    enum Priority {
        case critical
        case high
        case medium
        case low
    }
    
    enum Category {
        case modelImprovement
        case dataQuality
        case parameterTuning
        case testing
        case deployment
    }
    
    struct Trend {
        let modelName: String
        let trendDirection: TrendDirection
        let changePercentage: Float
        let significance: TrendSignificance
    }
    
    enum TrendDirection {
        case improving
        case declining
        case stable
    }
    
    enum TrendSignificance {
        case significant
        case moderate
        case minor
    }
    
    // MARK: - Analysis Methods
    
    /// Analyze test results and generate comprehensive report
    static func analyzeResults(_ results: [String: ComprehensiveAITests.TestResult]) -> AnalysisResult {
        let modelPerformance = analyzeModelPerformance(results)
        let deploymentReadiness = assessDeploymentReadiness(results)
        let recommendations = generateRecommendations(results, modelPerformance: modelPerformance)
        let trends = analyzeTrends(results)
        let overallScore = calculateOverallScore(results)
        let summary = generateSummary(results, deploymentReadiness: deploymentReadiness)
        
        return AnalysisResult(
            overallScore: overallScore,
            deploymentReadiness: deploymentReadiness,
            modelPerformance: modelPerformance,
            recommendations: recommendations,
            trends: trends,
            summary: summary
        )
    }
    
    /// Analyze individual model performance
    private static func analyzeModelPerformance(_ results: [String: ComprehensiveAITests.TestResult]) -> [String: ModelPerformance] {
        var modelPerformance: [String: ModelPerformance] = [:]
        
        for (modelName, result) in results {
            let performanceLevel = determinePerformanceLevel(result.accuracy)
            let issues = identifyIssues(result)
            let strengths = identifyStrengths(result)
            
            modelPerformance[modelName] = ModelPerformance(
                accuracy: result.accuracy,
                precision: result.precision,
                recall: result.recall,
                f1Score: result.f1Score,
                testCases: result.testCases,
                passed: result.passed,
                performanceLevel: performanceLevel,
                issues: issues,
                strengths: strengths
            )
        }
        
        return modelPerformance
    }
    
    /// Assess deployment readiness
    private static func assessDeploymentReadiness(_ results: [String: ComprehensiveAITests.TestResult]) -> DeploymentReadiness {
        let passedModels = results.values.filter { $0.passed }.count
        let totalModels = results.count
        let passRate = Float(passedModels) / Float(totalModels)
        
        let averageAccuracy = results.values.map { $0.accuracy }.reduce(0, +) / Float(totalModels)
        
        // Check for critical failures
        let criticalFailures = results.values.filter { $0.accuracy < 0.6 }.count
        
        if criticalFailures > 0 {
            return .critical
        } else if passRate >= 0.9 && averageAccuracy >= 0.9 {
            return .ready
        } else if passRate >= 0.7 && averageAccuracy >= 0.8 {
            return .conditional
        } else {
            return .notReady
        }
    }
    
    /// Generate recommendations based on analysis
    private static func generateRecommendations(
        _ results: [String: ComprehensiveAITests.TestResult],
        modelPerformance: [String: ModelPerformance]
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Analyze each model for specific recommendations
        for (modelName, performance) in modelPerformance {
            if !performance.passed {
                recommendations.append(createModelImprovementRecommendation(modelName: modelName, performance: performance))
            }
            
            if performance.accuracy < 0.8 {
                recommendations.append(createParameterTuningRecommendation(modelName: modelName, performance: performance))
            }
            
            if performance.testCases < 100 {
                recommendations.append(createTestingRecommendation(modelName: modelName, performance: performance))
            }
        }
        
        // Overall system recommendations
        let overallPassRate = Float(results.values.filter { $0.passed }.count) / Float(results.count)
        if overallPassRate < 0.8 {
            recommendations.append(createSystemImprovementRecommendation())
        }
        
        return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    /// Analyze trends (placeholder for future implementation)
    private static func analyzeTrends(_ results: [String: ComprehensiveAITests.TestResult]) -> [Trend] {
        // This would compare with historical results
        // For now, return empty array
        return []
    }
    
    /// Calculate overall score
    private static func calculateOverallScore(_ results: [String: ComprehensiveAITests.TestResult]) -> Float {
        let averageAccuracy = results.values.map { $0.accuracy }.reduce(0, +) / Float(results.count)
        let passRate = Float(results.values.filter { $0.passed }.count) / Float(results.count)
        
        // Weighted combination: 70% accuracy, 30% pass rate
        return (averageAccuracy * 0.7) + (passRate * 0.3)
    }
    
    /// Generate summary text
    private static func generateSummary(
        _ results: [String: ComprehensiveAITests.TestResult],
        deploymentReadiness: DeploymentReadiness
    ) -> String {
        let passedModels = results.values.filter { $0.passed }.count
        let totalModels = results.count
        let averageAccuracy = results.values.map { $0.accuracy }.reduce(0, +) / Float(totalModels)
        
        switch deploymentReadiness {
        case .ready:
            return "🎉 Excellent! All AI models are performing well and ready for deployment. Average accuracy: \(String(format: "%.1f%%", averageAccuracy * 100))"
            
        case .conditional:
            return "⚠️ Good performance overall, but some models need attention. \(passedModels)/\(totalModels) models passed with \(String(format: "%.1f%%", averageAccuracy * 100)) average accuracy."
            
        case .notReady:
            return "❌ Significant issues detected. Only \(passedModels)/\(totalModels) models passed. Average accuracy: \(String(format: "%.1f%%", averageAccuracy * 100)). Deployment not recommended."
            
        case .critical:
            return "🚨 Critical failures detected! Immediate attention required. System is not ready for deployment."
        }
    }
    
    // MARK: - Helper Methods
    
    private static func determinePerformanceLevel(_ accuracy: Float) -> PerformanceLevel {
        switch accuracy {
        case 0.95...:
            return .excellent
        case 0.85..<0.95:
            return .good
        case 0.75..<0.85:
            return .acceptable
        case 0.60..<0.75:
            return .poor
        default:
            return .critical
        }
    }
    
    private static func identifyIssues(_ result: ComprehensiveAITests.TestResult) -> [String] {
        var issues: [String] = []
        
        if !result.passed {
            issues.append("Failed to meet accuracy threshold")
        }
        
        if result.accuracy < 0.8 {
            issues.append("Low accuracy performance")
        }
        
        if result.testCases < 100 {
            issues.append("Insufficient test coverage")
        }
        
        if result.f1Score < 0.8 {
            issues.append("Poor F1 score indicates precision/recall issues")
        }
        
        return issues
    }
    
    private static func identifyStrengths(_ result: ComprehensiveAITests.TestResult) -> [String] {
        var strengths: [String] = []
        
        if result.accuracy >= 0.9 {
            strengths.append("High accuracy performance")
        }
        
        if result.testCases >= 200 {
            strengths.append("Comprehensive test coverage")
        }
        
        if result.f1Score >= 0.9 {
            strengths.append("Excellent precision and recall")
        }
        
        if result.passed {
            strengths.append("Meets all accuracy requirements")
        }
        
        return strengths
    }
    
    // MARK: - Recommendation Creators
    
    private static func createModelImprovementRecommendation(
        modelName: String,
        performance: ModelPerformance
    ) -> Recommendation {
        return Recommendation(
            priority: .high,
            category: .modelImprovement,
            title: "Improve \(modelName) Performance",
            description: "The \(modelName) model is not meeting accuracy requirements.",
            actionItems: [
                "Review model parameters and hyperparameters",
                "Analyze training data quality and quantity",
                "Consider model architecture improvements",
                "Implement additional validation techniques"
            ]
        )
    }
    
    private static func createParameterTuningRecommendation(
        modelName: String,
        performance: ModelPerformance
    ) -> Recommendation {
        return Recommendation(
            priority: .medium,
            category: .parameterTuning,
            title: "Tune \(modelName) Parameters",
            description: "The \(modelName) model could benefit from parameter optimization.",
            actionItems: [
                "Perform grid search or random search for optimal parameters",
                "Use cross-validation to validate parameter choices",
                "Consider automated hyperparameter tuning",
                "Monitor performance metrics during tuning"
            ]
        )
    }
    
    private static func createTestingRecommendation(
        modelName: String,
        performance: ModelPerformance
    ) -> Recommendation {
        return Recommendation(
            priority: .medium,
            category: .testing,
            title: "Expand \(modelName) Test Coverage",
            description: "The \(modelName) model needs more comprehensive testing.",
            actionItems: [
                "Increase test case count to at least 200",
                "Add edge case testing scenarios",
                "Implement stress testing",
                "Add integration testing with other models"
            ]
        )
    }
    
    private static func createSystemImprovementRecommendation() -> Recommendation {
        return Recommendation(
            priority: .critical,
            category: .deployment,
            title: "System-Wide Improvements Required",
            description: "Multiple models are underperforming, indicating systemic issues.",
            actionItems: [
                "Review overall system architecture",
                "Improve data pipeline and preprocessing",
                "Implement better model validation strategies",
                "Consider ensemble methods for improved performance"
            ]
        )
    }
}

// MARK: - Report Generation

extension TestResultsAnalyzer {
    
    /// Generate comprehensive analysis report
    static func generateReport(_ results: [String: ComprehensiveAITests.TestResult]) -> String {
        let analysis = analyzeResults(results)
        
        var report = "📊 AI Model Test Results Analysis Report\n"
        report += String(repeating: "=", count: 50) + "\n\n"
        
        // Summary
        report += "📋 SUMMARY\n"
        report += String(repeating: "-", count: 20) + "\n"
        report += analysis.summary + "\n\n"
        
        // Overall Score
        report += "🎯 OVERALL SCORE: \(String(format: "%.1f%%", analysis.overallScore * 100))\n"
        report += "🚀 DEPLOYMENT READINESS: \(deploymentReadinessString(analysis.deploymentReadiness))\n\n"
        
        // Model Performance
        report += "📈 MODEL PERFORMANCE\n"
        report += String(repeating: "-", count: 20) + "\n"
        for (modelName, performance) in analysis.modelPerformance {
            report += "\(modelName):\n"
            report += "  Accuracy: \(String(format: "%.1f%%", performance.accuracy * 100))\n"
            report += "  Level: \(performanceLevelString(performance.performanceLevel))\n"
            report += "  Status: \(performance.passed ? "✅ PASSED" : "❌ FAILED")\n"
            
            if !performance.strengths.isEmpty {
                report += "  Strengths: \(performance.strengths.joined(separator: ", "))\n"
            }
            
            if !performance.issues.isEmpty {
                report += "  Issues: \(performance.issues.joined(separator: ", "))\n"
            }
            report += "\n"
        }
        
        // Recommendations
        if !analysis.recommendations.isEmpty {
            report += "💡 RECOMMENDATIONS\n"
            report += String(repeating: "-", count: 20) + "\n"
            for (index, recommendation) in analysis.recommendations.enumerated() {
                report += "\(index + 1). [\(priorityString(recommendation.priority))] \(recommendation.title)\n"
                report += "   \(recommendation.description)\n"
                report += "   Actions:\n"
                for action in recommendation.actionItems {
                    report += "   • \(action)\n"
                }
                report += "\n"
            }
        }
        
        return report
    }
    
    private static func deploymentReadinessString(_ readiness: DeploymentReadiness) -> String {
        switch readiness {
        case .ready: return "✅ READY"
        case .conditional: return "⚠️ CONDITIONAL"
        case .notReady: return "❌ NOT READY"
        case .critical: return "🚨 CRITICAL"
        }
    }
    
    private static func performanceLevelString(_ level: PerformanceLevel) -> String {
        switch level {
        case .excellent: return "🌟 EXCELLENT"
        case .good: return "✅ GOOD"
        case .acceptable: return "⚠️ ACCEPTABLE"
        case .poor: return "❌ POOR"
        case .critical: return "🚨 CRITICAL"
        }
    }
    
    private static func priorityString(_ priority: Priority) -> String {
        switch priority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        }
    }
}

// MARK: - Priority Raw Values

extension TestResultsAnalyzer.Priority {
    var rawValue: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}
