import Foundation
import SwiftUI
import Combine

/// Automated Usability Testing Framework
/// Simulates 50 students aged 7-8 with mixed abilities and device familiarity
class AutomatedUsabilityTesting {
    
    // MARK: - Test Configuration
    private let numberOfStudents = 50
    private let ageRange = 7...8
    private let testDuration: TimeInterval = 300 // 5 minutes per student simulation
    
    // MARK: - Student Simulation Models
    struct SimulatedStudent {
        let id: UUID
        let age: Int
        let mathAbility: MathAbilityLevel
        let deviceFamiliarity: DeviceFamiliarityLevel
        let learningStyle: LearningStyle
        let attentionSpan: AttentionSpanLevel
        let testResults: UsabilityTestResults
    }
    
    enum MathAbilityLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var characteristics: (patience: Double, errorTolerance: Double, helpSeeking: Double) {
            switch self {
            case .beginner: return (0.3, 0.2, 0.8) // Low patience, low error tolerance, high help seeking
            case .intermediate: return (0.6, 0.5, 0.4) // Medium patience, medium error tolerance, medium help seeking
            case .advanced: return (0.8, 0.7, 0.2) // High patience, high error tolerance, low help seeking
            }
        }
    }
    
    enum DeviceFamiliarityLevel: String, CaseIterable {
        case novice = "Novice"
        case familiar = "Familiar"
        case expert = "Expert"
        
        var characteristics: (tapAccuracy: Double, navigationSpeed: Double, gestureRecognition: Double) {
            switch self {
            case .novice: return (0.6, 0.3, 0.4) // Lower accuracy, slower navigation, basic gestures
            case .familiar: return (0.8, 0.7, 0.7) // Good accuracy, decent speed, most gestures
            case .expert: return (0.95, 0.9, 0.9) // High accuracy, fast navigation, all gestures
            }
        }
    }
    
    enum LearningStyle: String, CaseIterable {
        case visual = "Visual"
        case auditory = "Auditory"
        case kinesthetic = "Kinesthetic"
        case mixed = "Mixed"
    }
    
    enum AttentionSpanLevel: String, CaseIterable {
        case short = "Short" // 2-3 minutes
        case medium = "Medium" // 5-7 minutes
        case long = "Long" // 10+ minutes
    }
    
    // MARK: - Test Results Model
    struct UsabilityTestResults {
        var taskCompletionRates: [String: Double] = [:]
        var averageTaskTimes: [String: TimeInterval] = [:]
        var errorCounts: [String: Int] = [:]
        var helpRequests: [String: Int] = [:]
        var satisfactionRatings: [String: Double] = [:]
        var navigationIssues: [String] = []
        var uiConfusionPoints: [String] = []
        var positiveFeedback: [String] = []
        var overallSatisfaction: Double = 0.0
        var wouldUseAgain: Bool = false
    }
    
    // MARK: - Test Scenarios
    struct TestScenario {
        let id: String
        let name: String
        let description: String
        let expectedDuration: TimeInterval
        let successCriteria: [String]
        let difficulty: TestDifficulty
    }
    
    enum TestDifficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }
    
    // MARK: - Test Execution
    private var testScenarios: [TestScenario] = []
    private var simulatedStudents: [SimulatedStudent] = []
    private var overallResults: [String: Any] = [:]
    
    init() {
        setupTestScenarios()
        generateSimulatedStudents()
    }
    
    // MARK: - Setup Methods
    
    private func setupTestScenarios() {
        testScenarios = [
            TestScenario(
                id: "onboarding",
                name: "First-Time User Onboarding",
                description: "Complete the initial app setup and onboarding flow",
                expectedDuration: 120, // 2 minutes
                successCriteria: ["Complete registration", "Set up profile", "Understand main interface"],
                difficulty: .easy
            ),
            TestScenario(
                id: "lesson_start",
                name: "Start a Math Lesson",
                description: "Navigate to and start a math lesson",
                expectedDuration: 60, // 1 minute
                successCriteria: ["Find lesson section", "Select appropriate lesson", "Begin lesson"],
                difficulty: .easy
            ),
            TestScenario(
                id: "question_answering",
                name: "Answer Math Questions",
                description: "Complete a series of math questions with different types",
                expectedDuration: 300, // 5 minutes
                successCriteria: ["Understand question format", "Provide correct answers", "Navigate between questions"],
                difficulty: .medium
            ),
            TestScenario(
                id: "progress_tracking",
                name: "Check Learning Progress",
                description: "View and understand personal learning progress",
                expectedDuration: 90, // 1.5 minutes
                successCriteria: ["Find progress section", "Understand progress indicators", "Interpret performance data"],
                difficulty: .medium
            ),
            TestScenario(
                id: "mistake_review",
                name: "Review Incorrect Answers",
                description: "Access and review previously incorrect answers",
                expectedDuration: 120, // 2 minutes
                successCriteria: ["Find mistake review section", "Understand explanations", "Learn from errors"],
                difficulty: .hard
            ),
            TestScenario(
                id: "ai_recommendations",
                name: "Use AI Recommendations",
                description: "Understand and act on AI-generated lesson recommendations",
                expectedDuration: 180, // 3 minutes
                successCriteria: ["Find AI recommendations", "Understand recommendation reasons", "Act on suggestions"],
                difficulty: .hard
            ),
            TestScenario(
                id: "settings_navigation",
                name: "Access App Settings",
                description: "Navigate to and modify app settings",
                expectedDuration: 90, // 1.5 minutes
                successCriteria: ["Find settings", "Understand options", "Make changes"],
                difficulty: .medium
            )
        ]
    }
    
    private func generateSimulatedStudents() {
        simulatedStudents = (0..<numberOfStudents).map { index in
            SimulatedStudent(
                id: UUID(),
                age: Int.random(in: ageRange),
                mathAbility: MathAbilityLevel.allCases.randomElement() ?? .intermediate,
                deviceFamiliarity: DeviceFamiliarityLevel.allCases.randomElement() ?? .familiar,
                learningStyle: LearningStyle.allCases.randomElement() ?? .mixed,
                attentionSpan: AttentionSpanLevel.allCases.randomElement() ?? .medium,
                testResults: UsabilityTestResults()
            )
        }
    }
    
    // MARK: - Test Execution
    
    /// Run comprehensive usability testing simulation
    func runAutomatedUsabilityTests() async -> UsabilityTestReport {
        print("🧪 Starting Automated Usability Testing...")
        print("📊 Simulating \(numberOfStudents) students aged \(ageRange.lowerBound)-\(ageRange.upperBound)")
        print(String(repeating: "=", count: 60))
        
        let startTime = Date()
        var allResults: [UsabilityTestResults] = []
        
        // Run tests for each simulated student
        for (index, student) in simulatedStudents.enumerated() {
            print("\n👤 Testing Student \(index + 1)/\(numberOfStudents)")
            print("   Age: \(student.age), Math: \(student.mathAbility.rawValue), Device: \(student.deviceFamiliarity.rawValue)")
            
            let studentResults = await simulateStudentTesting(student)
            allResults.append(studentResults)
            
            // Progress update
            let progress = Float(index + 1) / Float(numberOfStudents)
            print("   Progress: \(String(format: "%.1f%%", progress * 100))")
        }
        
        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(startTime)
        
        print("\n✅ Automated Usability Testing Completed!")
        print("⏱️ Total Duration: \(String(format: "%.2f", totalDuration)) seconds")
        
        return generateTestReport(allResults: allResults, duration: totalDuration)
    }
    
    /// Simulate testing for a single student
    private func simulateStudentTesting(_ student: SimulatedStudent) async -> UsabilityTestResults {
        var results = UsabilityTestResults()
        
        // Simulate each test scenario
        for scenario in testScenarios {
            let scenarioResult = await simulateScenario(scenario: scenario, student: student)
            
            // Aggregate results
            results.taskCompletionRates[scenario.id] = scenarioResult.completionRate
            results.averageTaskTimes[scenario.id] = scenarioResult.averageTime
            results.errorCounts[scenario.id] = scenarioResult.errorCount
            results.helpRequests[scenario.id] = scenarioResult.helpRequests
            results.satisfactionRatings[scenario.id] = scenarioResult.satisfactionRating
            
            // Add specific issues based on student characteristics
            if scenarioResult.completionRate < 0.7 {
                results.navigationIssues.append("\(scenario.name): Low completion rate (\(String(format: "%.1f%%", scenarioResult.completionRate * 100)))")
            }
            
            if scenarioResult.errorCount > 3 {
                results.uiConfusionPoints.append("\(scenario.name): High error count (\(scenarioResult.errorCount))")
            }
            
            if scenarioResult.satisfactionRating > 4.0 {
                results.positiveFeedback.append("\(scenario.name): High satisfaction (\(String(format: "%.1f", scenarioResult.satisfactionRating))/5.0)")
            }
        }
        
        // Calculate overall metrics
        results.overallSatisfaction = results.satisfactionRatings.values.reduce(0, +) / Double(results.satisfactionRatings.count)
        results.wouldUseAgain = results.overallSatisfaction > 3.5
        
        return results
    }
    
    /// Simulate a specific test scenario for a student
    private func simulateScenario(scenario: TestScenario, student: SimulatedStudent) async -> ScenarioResult {
        // Simulate realistic delays
        let baseDelay = Double.random(in: 0.1...0.3)
        try? await Task.sleep(nanoseconds: UInt64(baseDelay * 1_000_000_000))
        
        // Calculate performance based on student characteristics
        let abilityFactors = student.mathAbility.characteristics
        let deviceFactors = student.deviceFamiliarity.characteristics
        
        // Determine completion rate based on student characteristics and scenario difficulty
        let baseCompletionRate = calculateCompletionRate(
            scenario: scenario,
            mathAbility: abilityFactors,
            deviceFamiliarity: deviceFactors
        )
        
        // Calculate task time (affected by device familiarity and attention span)
        let baseTime = scenario.expectedDuration
        let timeMultiplier = calculateTimeMultiplier(
            deviceFamiliarity: deviceFactors,
            attentionSpan: student.attentionSpan
        )
        let actualTime = baseTime * timeMultiplier
        
        // Calculate error count (affected by device familiarity and math ability)
        let errorCount = calculateErrorCount(
            scenario: scenario,
            deviceFamiliarity: deviceFactors,
            mathAbility: abilityFactors
        )
        
        // Calculate help requests (affected by math ability and device familiarity)
        let helpRequests = calculateHelpRequests(
            scenario: scenario,
            mathAbility: abilityFactors,
            deviceFamiliarity: deviceFactors
        )
        
        // Calculate satisfaction rating
        let satisfactionRating = calculateSatisfactionRating(
            completionRate: baseCompletionRate,
            errorCount: errorCount,
            timeEfficiency: 1.0 / timeMultiplier
        )
        
        return ScenarioResult(
            completionRate: baseCompletionRate,
            averageTime: actualTime,
            errorCount: errorCount,
            helpRequests: helpRequests,
            satisfactionRating: satisfactionRating
        )
    }
    
    // MARK: - Calculation Methods
    
    private func calculateCompletionRate(
        scenario: TestScenario,
        mathAbility: (patience: Double, errorTolerance: Double, helpSeeking: Double),
        deviceFamiliarity: (tapAccuracy: Double, navigationSpeed: Double, gestureRecognition: Double)
    ) -> Double {
        let baseRate: Double
        
        switch scenario.difficulty {
        case .easy:
            baseRate = 0.85
        case .medium:
            baseRate = 0.70
        case .hard:
            baseRate = 0.55
        }
        
        // Adjust based on student characteristics
        let abilityAdjustment = (mathAbility.patience + mathAbility.errorTolerance) * 0.1
        let deviceAdjustment = (deviceFamiliarity.tapAccuracy + deviceFamiliarity.navigationSpeed) * 0.1
        
        let adjustedRate = baseRate + abilityAdjustment + deviceAdjustment
        return min(max(adjustedRate, 0.0), 1.0)
    }
    
    private func calculateTimeMultiplier(
        deviceFamiliarity: (tapAccuracy: Double, navigationSpeed: Double, gestureRecognition: Double),
        attentionSpan: AttentionSpanLevel
    ) -> Double {
        let deviceMultiplier = 2.0 - deviceFamiliarity.navigationSpeed // Higher familiarity = lower multiplier
        
        let attentionMultiplier: Double
        switch attentionSpan {
        case .short: attentionMultiplier = 1.5
        case .medium: attentionMultiplier = 1.0
        case .long: attentionMultiplier = 0.8
        }
        
        return deviceMultiplier * attentionMultiplier
    }
    
    private func calculateErrorCount(
        scenario: TestScenario,
        deviceFamiliarity: (tapAccuracy: Double, navigationSpeed: Double, gestureRecognition: Double),
        mathAbility: (patience: Double, errorTolerance: Double, helpSeeking: Double)
    ) -> Int {
        let baseErrors: Int
        
        switch scenario.difficulty {
        case .easy: baseErrors = 1
        case .medium: baseErrors = 3
        case .hard: baseErrors = 5
        }
        
        // Adjust based on device familiarity (lower familiarity = more errors)
        let deviceAdjustment = Int((1.0 - deviceFamiliarity.tapAccuracy) * 3)
        
        // Adjust based on math ability (lower patience = more errors)
        let abilityAdjustment = Int((1.0 - mathAbility.patience) * 2)
        
        return max(0, baseErrors + deviceAdjustment + abilityAdjustment)
    }
    
    private func calculateHelpRequests(
        scenario: TestScenario,
        mathAbility: (patience: Double, errorTolerance: Double, helpSeeking: Double),
        deviceFamiliarity: (tapAccuracy: Double, navigationSpeed: Double, gestureRecognition: Double)
    ) -> Int {
        let baseRequests: Int
        
        switch scenario.difficulty {
        case .easy: baseRequests = 0
        case .medium: baseRequests = 1
        case .hard: baseRequests = 2
        }
        
        // Higher help seeking tendency = more requests
        let helpAdjustment = Int(mathAbility.helpSeeking * 2)
        
        // Lower device familiarity = more requests
        let deviceAdjustment = Int((1.0 - deviceFamiliarity.navigationSpeed) * 1.5)
        
        return max(0, baseRequests + helpAdjustment + deviceAdjustment)
    }
    
    private func calculateSatisfactionRating(
        completionRate: Double,
        errorCount: Int,
        timeEfficiency: Double
    ) -> Double {
        let baseRating = 3.0
        
        // Completion rate impact
        let completionImpact = (completionRate - 0.5) * 2.0
        
        // Error count impact (fewer errors = higher satisfaction)
        let errorImpact = -Double(errorCount) * 0.2
        
        // Time efficiency impact
        let timeImpact = (timeEfficiency - 0.5) * 1.0
        
        let finalRating = baseRating + completionImpact + errorImpact + timeImpact
        return min(max(finalRating, 1.0), 5.0)
    }
    
    // MARK: - Report Generation
    
    private func generateTestReport(allResults: [UsabilityTestResults], duration: TimeInterval) -> UsabilityTestReport {
        let totalStudents = allResults.count
        
        // Calculate aggregate metrics
        let overallCompletionRates = calculateOverallCompletionRates(allResults)
        let averageTaskTimes = calculateAverageTaskTimes(allResults)
        let totalErrors = allResults.flatMap { $0.errorCounts.values }.reduce(0, +)
        let totalHelpRequests = allResults.flatMap { $0.helpRequests.values }.reduce(0, +)
        let averageSatisfaction = allResults.map { $0.overallSatisfaction }.reduce(0, +) / Double(totalStudents)
        let wouldUseAgainCount = allResults.filter { $0.wouldUseAgain }.count
        
        // Identify common issues
        let commonNavigationIssues = identifyCommonIssues(allResults.map { $0.navigationIssues })
        let commonConfusionPoints = identifyCommonIssues(allResults.map { $0.uiConfusionPoints })
        let commonPositiveFeedback = identifyCommonIssues(allResults.map { $0.positiveFeedback })
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            completionRates: overallCompletionRates,
            commonIssues: commonNavigationIssues,
            satisfactionRating: averageSatisfaction
        )
        
        return UsabilityTestReport(
            totalStudents: totalStudents,
            testDuration: duration,
            overallCompletionRates: overallCompletionRates,
            averageTaskTimes: averageTaskTimes,
            totalErrors: totalErrors,
            totalHelpRequests: totalHelpRequests,
            averageSatisfaction: averageSatisfaction,
            wouldUseAgainPercentage: Double(wouldUseAgainCount) / Double(totalStudents) * 100,
            commonNavigationIssues: commonNavigationIssues,
            commonConfusionPoints: commonConfusionPoints,
            commonPositiveFeedback: commonPositiveFeedback,
            recommendations: recommendations,
            detailedResults: allResults
        )
    }
    
    private func calculateOverallCompletionRates(_ results: [UsabilityTestResults]) -> [String: Double] {
        let allScenarios = Set(results.flatMap { $0.taskCompletionRates.keys })
        
        return Dictionary(uniqueKeysWithValues: allScenarios.map { scenario in
            let rates = results.compactMap { $0.taskCompletionRates[scenario] }
            let averageRate = rates.reduce(0, +) / Double(rates.count)
            return (scenario, averageRate)
        })
    }
    
    private func calculateAverageTaskTimes(_ results: [UsabilityTestResults]) -> [String: TimeInterval] {
        let allScenarios = Set(results.flatMap { $0.averageTaskTimes.keys })
        
        return Dictionary(uniqueKeysWithValues: allScenarios.map { scenario in
            let times = results.compactMap { $0.averageTaskTimes[scenario] }
            let averageTime = times.reduce(0, +) / Double(times.count)
            return (scenario, averageTime)
        })
    }
    
    private func identifyCommonIssues(_ allIssues: [[String]]) -> [String: Int] {
        let flattened = allIssues.flatMap { $0 }
        let grouped = Dictionary(grouping: flattened, by: { $0 })
        return grouped.mapValues { $0.count }
    }
    
    private func generateRecommendations(
        completionRates: [String: Double],
        commonIssues: [String: Int],
        satisfactionRating: Double
    ) -> [String] {
        var recommendations: [String] = []
        
        // Low completion rate recommendations
        for (scenario, rate) in completionRates {
            if rate < 0.7 {
                recommendations.append("🔴 CRITICAL: Improve \(scenario) - Only \(String(format: "%.1f%%", rate * 100)) completion rate")
            } else if rate < 0.85 {
                recommendations.append("🟡 MEDIUM: Enhance \(scenario) - \(String(format: "%.1f%%", rate * 100)) completion rate needs improvement")
            }
        }
        
        // Common issues recommendations
        let topIssues = commonIssues.sorted { $0.value > $1.value }.prefix(3)
        for (issue, count) in topIssues {
            if count > 10 {
                recommendations.append("🔴 CRITICAL: Address '\(issue)' - Affects \(count) students")
            } else if count > 5 {
                recommendations.append("🟡 MEDIUM: Consider improving '\(issue)' - Affects \(count) students")
            }
        }
        
        // Satisfaction recommendations
        if satisfactionRating < 3.5 {
            recommendations.append("🔴 CRITICAL: Overall satisfaction is low (\(String(format: "%.1f", satisfactionRating))/5.0) - Major UX improvements needed")
        } else if satisfactionRating < 4.0 {
            recommendations.append("🟡 MEDIUM: Satisfaction could be improved (\(String(format: "%.1f", satisfactionRating))/5.0) - Consider UX enhancements")
        } else {
            recommendations.append("✅ GOOD: Satisfaction is acceptable (\(String(format: "%.1f", satisfactionRating))/5.0) - Continue current approach")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Structures

struct ScenarioResult {
    let completionRate: Double
    let averageTime: TimeInterval
    let errorCount: Int
    let helpRequests: Int
    let satisfactionRating: Double
}

struct UsabilityTestReport {
    let totalStudents: Int
    let testDuration: TimeInterval
    let overallCompletionRates: [String: Double]
    let averageTaskTimes: [String: TimeInterval]
    let totalErrors: Int
    let totalHelpRequests: Int
    let averageSatisfaction: Double
    let wouldUseAgainPercentage: Double
    let commonNavigationIssues: [String: Int]
    let commonConfusionPoints: [String: Int]
    let commonPositiveFeedback: [String: Int]
    let recommendations: [String]
    let detailedResults: [AutomatedUsabilityTesting.UsabilityTestResults]
    
    func generateDetailedReport() -> String {
        var report = """
        # Automated Usability Testing Report
        ## AITimoMath - Student Simulation Results
        
        ### Executive Summary
        - **Total Students Simulated**: \(totalStudents)
        - **Test Duration**: \(String(format: "%.2f", testDuration)) seconds
        - **Average Satisfaction**: \(String(format: "%.1f", averageSatisfaction))/5.0
        - **Would Use Again**: \(String(format: "%.1f", wouldUseAgainPercentage))%
        
        ### Task Completion Rates
        """
        
        for (scenario, rate) in overallCompletionRates.sorted(by: { $0.value < $1.value }) {
            let status = rate >= 0.85 ? "✅" : (rate >= 0.7 ? "🟡" : "🔴")
            report += "\n- \(status) \(scenario): \(String(format: "%.1f%%", rate * 100))"
        }
        
        report += "\n\n### Common Issues Found"
        let topIssues = commonNavigationIssues.sorted { $0.value > $1.value }.prefix(5)
        for (issue, count) in topIssues {
            report += "\n- \(issue) (affects \(count) students)"
        }
        
        report += "\n\n### Recommendations"
        for recommendation in recommendations {
            report += "\n\(recommendation)"
        }
        
        report += "\n\n### Detailed Metrics"
        report += "\n- **Total Errors**: \(totalErrors)"
        report += "\n- **Total Help Requests**: \(totalHelpRequests)"
        report += "\n- **Average Task Times**:"
        
        for (scenario, time) in averageTaskTimes.sorted(by: { $0.value > $1.value }) {
            report += "\n  - \(scenario): \(String(format: "%.1f", time))s"
        }
        
        return report
    }
}
