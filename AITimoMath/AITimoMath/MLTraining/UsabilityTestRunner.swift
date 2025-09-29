import Foundation

/// Usability Test Runner - Orchestrates automated usability testing
class UsabilityTestRunner {
    
    /// Run comprehensive usability tests
    func runUsabilityTests() async -> [String] {
        let tester = AutomatedUsabilityTesting()
        let report = await tester.runAutomatedUsabilityTests()
        
        return generateTestOutput(report: report)
    }
    
    /// Generate formatted test output
    private func generateTestOutput(report: UsabilityTestReport) -> [String] {
        var output: [String] = []
        
        output.append("🧪 AUTOMATED USABILITY TESTING RESULTS")
        output.append(String(repeating: "=", count: 50))
        output.append("")
        
        // Executive Summary
        output.append("📊 EXECUTIVE SUMMARY")
        output.append("Total Students: \(report.totalStudents)")
        output.append("Test Duration: \(String(format: "%.2f", report.testDuration))s")
        output.append("Average Satisfaction: \(String(format: "%.1f", report.averageSatisfaction))/5.0")
        output.append("Would Use Again: \(String(format: "%.1f", report.wouldUseAgainPercentage))%")
        output.append("")
        
        // Task Performance
        output.append("📈 TASK COMPLETION RATES")
        for (scenario, rate) in report.overallCompletionRates.sorted(by: { $0.value < $1.value }) {
            let status = rate >= 0.85 ? "✅ EXCELLENT" : (rate >= 0.7 ? "🟡 GOOD" : "🔴 NEEDS IMPROVEMENT")
            output.append("\(status) \(scenario): \(String(format: "%.1f%%", rate * 100))")
        }
        output.append("")
        
        // Critical Issues
        output.append("🚨 CRITICAL ISSUES")
        let criticalIssues = report.commonNavigationIssues.filter { $0.value > 10 }
        if criticalIssues.isEmpty {
            output.append("✅ No critical issues found!")
        } else {
            for (issue, count) in criticalIssues.sorted(by: { $0.value > $1.value }) {
                output.append("🔴 \(issue) (affects \(count) students)")
            }
        }
        output.append("")
        
        // Recommendations
        output.append("💡 RECOMMENDATIONS")
        for recommendation in report.recommendations {
            output.append(recommendation)
        }
        output.append("")
        
        // Performance Metrics
        output.append("📊 PERFORMANCE METRICS")
        output.append("Total Errors: \(report.totalErrors)")
        output.append("Total Help Requests: \(report.totalHelpRequests)")
        output.append("Average Task Times:")
        for (scenario, time) in report.averageTaskTimes.sorted(by: { $0.value > $1.value }) {
            output.append("  • \(scenario): \(String(format: "%.1f", time))s")
        }
        
        return output
    }
}
