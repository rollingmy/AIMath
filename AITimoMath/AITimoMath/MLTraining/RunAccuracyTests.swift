import Foundation

/// Execute AI model accuracy tests with comprehensive reporting
class RunAccuracyTests {
    
    /// Execute comprehensive accuracy tests
    static func execute() {
        print("🚀 Starting AI Model Accuracy Testing...")
        print("Timestamp: \(Date())")
        print(String(repeating: "=", count: 80))
        
        let startTime = Date()
        
        // Run comprehensive tests
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Generate summary report
        generateSummaryReport(results: results, duration: duration)
        
        // Save detailed results
        saveDetailedResults(results: results, duration: duration)
        
        print("✅ Accuracy testing completed in \(String(format: "%.2f", duration)) seconds!")
    }
    
    /// Execute only accuracy tests (without basic functionality tests)
    static func executeAccuracyOnly() {
        print("🧪 Starting AI Model Accuracy Tests Only...")
        print("Timestamp: \(Date())")
        print(String(repeating: "=", count: 60))
        
        let startTime = Date()
        
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        generateSummaryReport(results: results, duration: duration)
        saveDetailedResults(results: results, duration: duration)
        
        print("✅ Accuracy testing completed in \(String(format: "%.2f", duration)) seconds!")
    }
    
    /// Execute tests with custom configuration
    static func executeWithConfiguration(
        accuracyThreshold: Float = 0.85,
        testIterations: Int = 1000,
        saveResults: Bool = true
    ) {
        print("⚙️ Starting AI Model Tests with Custom Configuration...")
        print("Accuracy Threshold: \(String(format: "%.2f%%", accuracyThreshold * 100))")
        print("Test Iterations: \(testIterations)")
        print("Save Results: \(saveResults)")
        print("Timestamp: \(Date())")
        print(String(repeating: "=", count: 60))
        
        let startTime = Date()
        
        // Create custom test configuration
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        generateSummaryReport(results: results, duration: duration)
        
        if saveResults {
            saveDetailedResults(results: results, duration: duration)
        }
        
        print("✅ Custom configuration testing completed in \(String(format: "%.2f", duration)) seconds!")
    }
    
    /// Generate summary report
    private static func generateSummaryReport(
        results: [String: ComprehensiveAITests.TestResult],
        duration: TimeInterval
    ) {
        print("\n📊 SUMMARY REPORT")
        print(String(repeating: "=", count: 40))
        
        var totalPassed = 0
        var totalTests = 0
        var totalAccuracy: Float = 0.0
        
        for (modelName, result) in results {
            let status = result.passed ? "✅ PASS" : "❌ FAIL"
            print("\(modelName): \(status) (\(String(format: "%.1f%%", result.accuracy * 100)))")
            
            if result.passed {
                totalPassed += 1
            }
            totalTests += 1
            totalAccuracy += result.accuracy
        }
        
        let overallSuccessRate = Float(totalPassed) / Float(totalTests)
        let averageAccuracy = totalAccuracy / Float(totalTests)
        
        print("\nOverall Results:")
        print("  Models Passed: \(totalPassed)/\(totalTests)")
        print("  Success Rate: \(String(format: "%.1f%%", overallSuccessRate * 100))")
        print("  Average Accuracy: \(String(format: "%.1f%%", averageAccuracy * 100))")
        print("  Test Duration: \(String(format: "%.2f", duration)) seconds")
        
        // Determine overall status
        if overallSuccessRate >= 0.8 {
            print("🎉 OVERALL STATUS: READY FOR DEPLOYMENT")
        } else if overallSuccessRate >= 0.6 {
            print("⚠️ OVERALL STATUS: NEEDS IMPROVEMENT")
        } else {
            print("❌ OVERALL STATUS: NOT READY FOR DEPLOYMENT")
        }
    }
    
    /// Save detailed results to file
    private static func saveDetailedResults(
        results: [String: ComprehensiveAITests.TestResult],
        duration: TimeInterval
    ) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let resultsURL = documentsPath.appendingPathComponent("AI_Accuracy_Test_Results_\(timestamp).json")
        
        // Create detailed results structure
        let detailedResults = DetailedTestResults(
            timestamp: Date(),
            duration: duration,
            results: results,
            summary: generateResultsSummary(results: results)
        )
        
        do {
            let jsonData = try JSONEncoder().encode(detailedResults)
            try jsonData.write(to: resultsURL)
            print("📁 Detailed results saved to: \(resultsURL.path)")
        } catch {
            print("❌ Error saving detailed results: \(error.localizedDescription)")
        }
    }
    
    /// Generate results summary
    private static func generateResultsSummary(
        results: [String: ComprehensiveAITests.TestResult]
    ) -> ResultsSummary {
        let totalPassed = results.values.filter { $0.passed }.count
        let totalModels = results.count
        let overallSuccessRate = Float(totalPassed) / Float(totalModels)
        let averageAccuracy = results.values.map { $0.accuracy }.reduce(0, +) / Float(totalModels)
        
        return ResultsSummary(
            totalModels: totalModels,
            passedModels: totalPassed,
            overallSuccessRate: overallSuccessRate,
            averageAccuracy: averageAccuracy,
            deploymentReady: overallSuccessRate >= 0.8
        )
    }
}

// MARK: - Supporting Data Structures

/// Detailed test results structure for JSON serialization
struct DetailedTestResults: Codable {
    let timestamp: Date
    let duration: TimeInterval
    let results: [String: ComprehensiveAITests.TestResult]
    let summary: ResultsSummary
}

/// Results summary for quick analysis
struct ResultsSummary: Codable {
    let totalModels: Int
    let passedModels: Int
    let overallSuccessRate: Float
    let averageAccuracy: Float
    let deploymentReady: Bool
}

// MARK: - Command Line Interface

/// Command line interface for running tests
class TestCommandLineInterface {
    
    /// Parse command line arguments and run appropriate tests
    static func runWithArguments(_ arguments: [String]) {
        if arguments.isEmpty {
            // Default: run all tests
            RunAccuracyTests.execute()
            return
        }
        
        let command = arguments[0].lowercased()
        
        switch command {
        case "accuracy", "acc":
            RunAccuracyTests.executeAccuracyOnly()
            
        case "all", "complete":
            RunAccuracyTests.execute()
            
        case "custom":
            if arguments.count >= 4 {
                let threshold = Float(arguments[1]) ?? 0.85
                let iterations = Int(arguments[2]) ?? 1000
                let saveResults = arguments[3].lowercased() == "true"
                RunAccuracyTests.executeWithConfiguration(
                    accuracyThreshold: threshold,
                    testIterations: iterations,
                    saveResults: saveResults
                )
            } else {
                print("Usage: custom <threshold> <iterations> <saveResults>")
                print("Example: custom 0.9 500 true")
            }
            
        case "help", "h":
            printHelp()
            
        default:
            print("Unknown command: \(command)")
            print("Use 'help' for available commands")
        }
    }
    
    /// Print help information
    private static func printHelp() {
        print("AI Model Accuracy Testing - Command Line Interface")
        print(String(repeating: "=", count: 50))
        print("Available commands:")
        print("  (no args)     - Run all tests (default)")
        print("  accuracy      - Run only accuracy tests")
        print("  all           - Run all tests")
        print("  custom        - Run with custom configuration")
        print("  help          - Show this help message")
        print("")
        print("Custom configuration usage:")
        print("  custom <threshold> <iterations> <saveResults>")
        print("  Example: custom 0.9 500 true")
        print("")
        print("Examples:")
        print("  swift RunAccuracyTests.swift")
        print("  swift RunAccuracyTests.swift accuracy")
        print("  swift RunAccuracyTests.swift custom 0.9 1000 true")
    }
}

// MARK: - Integration with Existing Test Infrastructure

/// Extension to integrate with existing test infrastructure
extension RunAccuracyTests {
    
    /// Run tests as part of the existing test suite
    static func runAsPartOfTestSuite() -> Bool {
        print("🧪 Running AI Model Accuracy Tests as part of test suite...")
        
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        // Check if all tests passed
        let allPassed = results.values.allSatisfy { $0.passed }
        
        if allPassed {
            print("✅ All AI model accuracy tests passed!")
        } else {
            print("❌ Some AI model accuracy tests failed!")
            for (modelName, result) in results {
                if !result.passed {
                    print("  - \(modelName): \(String(format: "%.1f%%", result.accuracy * 100)) accuracy")
                }
            }
        }
        
        return allPassed
    }
    
    /// Get test results for integration with CI/CD
    static func getTestResultsForCI() -> [String: Any] {
        let comprehensiveTests = ComprehensiveAITests()
        let results = comprehensiveTests.runAllAccuracyTests()
        
        var ciResults: [String: Any] = [:]
        
        for (modelName, result) in results {
            ciResults[modelName] = [
                "passed": result.passed,
                "accuracy": result.accuracy,
                "testCases": result.testCases,
                "details": result.details
            ]
        }
        
        // Add overall summary
        let totalPassed = results.values.filter { $0.passed }.count
        let totalModels = results.count
        let overallSuccessRate = Float(totalPassed) / Float(totalModels)
        
        ciResults["summary"] = [
            "totalModels": totalModels,
            "passedModels": totalPassed,
            "overallSuccessRate": overallSuccessRate,
            "deploymentReady": overallSuccessRate >= 0.8
        ]
        
        return ciResults
    }
}
