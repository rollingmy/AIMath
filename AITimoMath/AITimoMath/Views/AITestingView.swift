import SwiftUI

/// View for AI model testing and validation
/// This view provides a comprehensive interface for testing AI models
struct AITestingView: View {
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    @State private var selectedTestType: TestType = .all
    @State private var showDetailedResults = false
    @State private var testProgress: Float = 0.0
    @State private var currentTestStep = ""
    
    enum TestType: String, CaseIterable {
        case basic = "Basic Tests"
        case accuracy = "Accuracy Tests"
        case usability = "Usability Tests"
        case all = "All Tests"
        case custom = "Custom Configuration"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Text("AI Model Testing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Validate AI model accuracy and performance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Test Configuration
                VStack(alignment: .leading, spacing: 15) {
                    Text("Test Configuration")
                        .font(.headline)
                    
                    // Test type selector
                    Picker("Test Type", selection: $selectedTestType) {
                        ForEach(TestType.allCases, id: \.self) { testType in
                            Text(testType.rawValue).tag(testType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Custom configuration (if selected)
                    if selectedTestType == .custom {
                        CustomTestConfigurationView()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Controls
                VStack(spacing: 15) {
                    // Progress indicator
                    if isRunningTests {
                        VStack {
                            Text(currentTestStep)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: testProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                    }
                    
                    // Run tests button
                    Button(action: {
                        runSelectedTests()
                    }) {
                        HStack {
                            if isRunningTests {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isRunningTests ? "Running Tests..." : "Run \(selectedTestType.rawValue)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRunningTests ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRunningTests)
                    
                    // Quick test buttons
                    if !isRunningTests {
                        HStack(spacing: 10) {
                            Button("Quick Accuracy") {
                                selectedTestType = .accuracy
                                runSelectedTests()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Full Suite") {
                                selectedTestType = .all
                                runSelectedTests()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
                
                // Test Results
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Test Results")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Show Details") {
                                showDetailedResults.toggle()
                            }
                            .font(.caption)
                        }
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 5) {
                                ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                                    Text(result)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(resultColor(for: result))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDetailedResults) {
                DetailedTestResultsView(results: testResults)
            }
        }
    }
    
    /// Run the selected type of tests
    private func runSelectedTests() {
        isRunningTests = true
        testResults = []
        testProgress = 0.0
        currentTestStep = "Initializing tests..."
        
        Task {
            let testRunner = AIModelTestRunner()
            let results: [String]
            
            switch selectedTestType {
            case .basic:
                await MainActor.run {
                    currentTestStep = "Running basic functionality tests..."
                    testProgress = 0.3
                }
                results = testRunner.runTests()
                
            case .accuracy:
                await MainActor.run {
                    currentTestStep = "Running accuracy validation tests..."
                    testProgress = 0.5
                }
                results = testRunner.runAccuracyTests()
                
            case .usability:
                await MainActor.run {
                    currentTestStep = "Running automated usability tests..."
                    testProgress = 0.3
                }
                results = await runUsabilityTests()
                
            case .all:
                await MainActor.run {
                    currentTestStep = "Running complete test suite..."
                    testProgress = 0.2
                }
                results = testRunner.runAllTests()
                
            case .custom:
                await MainActor.run {
                    currentTestStep = "Running custom configuration tests..."
                    testProgress = 0.4
                }
                results = testRunner.runAccuracyTests() // For now, same as accuracy
            }
            
            await MainActor.run {
                testProgress = 1.0
                currentTestStep = "Tests completed!"
                self.testResults = results
                self.isRunningTests = false
                self.testProgress = 0.0
                self.currentTestStep = ""
            }
        }
    }
    
    /// Run automated usability tests
    private func runUsabilityTests() async -> [String] {
        let usabilityTester = AutomatedUsabilityTesting()
        let report = await usabilityTester.runAutomatedUsabilityTests()
        
        var results: [String] = []
        
        // Add summary results
        results.append("🧪 Automated Usability Testing Results")
        results.append("📊 Simulated \(report.totalStudents) students aged 7-8")
        results.append("⏱️ Test Duration: \(String(format: "%.2f", report.testDuration))s")
        results.append("⭐ Average Satisfaction: \(String(format: "%.1f", report.averageSatisfaction))/5.0")
        results.append("👍 Would Use Again: \(String(format: "%.1f", report.wouldUseAgainPercentage))%")
        
        // Add task completion rates
        results.append("\n📈 Task Completion Rates:")
        for (scenario, rate) in report.overallCompletionRates.sorted(by: { $0.value < $1.value }) {
            let status = rate >= 0.85 ? "✅" : (rate >= 0.7 ? "🟡" : "🔴")
            results.append("\(status) \(scenario): \(String(format: "%.1f%%", rate * 100))")
        }
        
        // Add top issues
        results.append("\n🚨 Top Issues Found:")
        let topIssues = report.commonNavigationIssues.sorted { $0.value > $1.value }.prefix(3)
        for (issue, count) in topIssues {
            results.append("🔴 \(issue) (affects \(count) students)")
        }
        
        // Add recommendations
        results.append("\n💡 Key Recommendations:")
        for recommendation in report.recommendations.prefix(5) {
            results.append(recommendation)
        }
        
        // Add detailed metrics
        results.append("\n📊 Detailed Metrics:")
        results.append("Total Errors: \(report.totalErrors)")
        results.append("Total Help Requests: \(report.totalHelpRequests)")
        
        return results
    }
    
    /// Determine color for test result line
    private func resultColor(for result: String) -> Color {
        if result.contains("✅") || result.contains("PASSED") {
            return Color.green.opacity(0.2)
        } else if result.contains("❌") || result.contains("FAILED") {
            return Color.red.opacity(0.2)
        } else if result.contains("⚠️") || result.contains("WARNING") {
            return Color.orange.opacity(0.2)
        } else if result.contains("🎉") || result.contains("SUCCESS") {
            return Color.blue.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Custom Test Configuration View

struct CustomTestConfigurationView: View {
    @State private var accuracyThreshold: Double = 0.85
    @State private var testIterations: Int = 1000
    @State private var saveResults: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Configuration")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Accuracy Threshold:")
                    Spacer()
                    Text("\(String(format: "%.0f%%", accuracyThreshold * 100))")
                        .foregroundColor(.secondary)
                }
                Slider(value: $accuracyThreshold, in: 0.5...0.95, step: 0.05)
                
                HStack {
                    Text("Test Iterations:")
                    Spacer()
                    Text("\(testIterations)")
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(testIterations) },
                    set: { testIterations = Int($0) }
                ), in: 100...2000, step: 100)
                
                Toggle("Save Results", isOn: $saveResults)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Detailed Test Results View

struct DetailedTestResultsView: View {
    let results: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        Text(result)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(resultColor(for: result))
                            .cornerRadius(6)
                    }
                }
                .padding()
            }
            .navigationTitle("Detailed Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func resultColor(for result: String) -> Color {
        if result.contains("✅") || result.contains("PASSED") {
            return Color.green.opacity(0.2)
        } else if result.contains("❌") || result.contains("FAILED") {
            return Color.red.opacity(0.2)
        } else if result.contains("⚠️") || result.contains("WARNING") {
            return Color.orange.opacity(0.2)
        } else if result.contains("🎉") || result.contains("SUCCESS") {
            return Color.blue.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

struct AITestingView_Previews: PreviewProvider {
    static var previews: some View {
        AITestingView()
    }
}
