import SwiftUI

struct PerformanceView: View {
    @ObservedObject var user: User
    @State private var selectedTimeRange: TimeRange = .week
    @State private var subjects = ["Logical Thinking", "Arithmetic", "Number Theory", "Geometry", "Combinatorics"]
    @State private var subjectPerformance: [SubjectPerformance] = []
    @State private var weaknesses: [String] = []
    @State private var isLoading = true
    
    // Time range options
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    // Subject performance model
    struct SubjectPerformance: Identifiable {
        let id = UUID()
        let subject: String
        let accuracy: Double
        let trend: Trend
        
        enum Trend {
            case up, down, stable
        }
    }
    
    // Load actual performance data
    private func loadPerformanceData() {
        isLoading = true
        
        Task {
            do {
                // Load actual performance data from user's lesson history
                let performanceService = PerformanceService.shared
                let subjectData = try await performanceService.calculateSubjectPerformance(userId: user.id)
                let weakAreas = try await performanceService.identifyWeakAreas(userId: user.id)
                
                await MainActor.run {
                    // Convert to SubjectPerformance format
                    var performance: [SubjectPerformance] = []
                    
                    for subject in subjects {
                        if let data = subjectData[subject] {
                            // Determine trend based on recent performance vs overall
                            let trend: SubjectPerformance.Trend
                            if data.accuracy > 0.8 {
                                trend = .up
                            } else if data.accuracy < 0.6 {
                                trend = .down
                            } else {
                                trend = .stable
                            }
                            
                            performance.append(SubjectPerformance(
                                subject: subject,
                                accuracy: data.accuracy * 100, // Convert to percentage
                                trend: trend
                            ))
                        } else {
                            // No data for this subject, show 0% accuracy
                            performance.append(SubjectPerformance(
                                subject: subject,
                                accuracy: 0.0,
                                trend: .stable
                            ))
                        }
                    }
                    
                    // Sort by accuracy (lowest first for improvement focus)
                    self.subjectPerformance = performance.sorted(by: { $0.accuracy < $1.accuracy })
                    self.weaknesses = weakAreas
                    self.isLoading = false
                }
            } catch {
                print("Error loading performance data: \(error)")
                await MainActor.run {
                    // Fallback to empty data if loading fails
                    self.subjectPerformance = []
                    self.weaknesses = []
                    self.isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Text("Performance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with time range selector
                    HStack {
                        Text("Performance Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    .padding(.bottom, 10)
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.top, 50)
                } else {
                    // MARK: - Overall Progress Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accuracy Trends")
                            .font(.headline)
                        
                        // Actual performance chart
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(subjectPerformance) { subject in
                                HStack {
                                    Text(subject.subject)
                                        .font(.caption)
                                        .frame(width: 120, alignment: .leading)
                                    
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .frame(height: 8)
                                            .foregroundColor(Color(.systemGray5))
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .frame(width: CGFloat(subject.accuracy / 100.0) * 200, height: 8)
                                            .foregroundColor(getAccuracyColor(subject.accuracy))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text("\(Int(subject.accuracy))%")
                                        .font(.caption)
                                        .frame(width: 40)
                                    
                                    // Trend indicator
                                    Image(systemName: getTrendIcon(subject.trend))
                                        .font(.caption)
                                        .foregroundColor(getTrendColor(subject.trend))
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // MARK: - Weak Areas Section
                    if !weaknesses.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Areas for Improvement")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(weaknesses, id: \.self) { weakness in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        
                                        Text(weakness)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // MARK: - Summary Statistics
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Summary")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Questions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(user.dailyCompletedQuestions)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Daily Goal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(user.dailyGoal)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for bottom navigation
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadPerformanceData()
        }
    }
    
    // Helper functions for UI
    private func getAccuracyColor(_ accuracy: Double) -> Color {
        switch accuracy {
        case 0..<60:
            return .red
        case 60..<80:
            return .orange
        case 80..<90:
            return .yellow
        default:
            return .green
        }
    }
    
    private func getTrendIcon(_ trend: SubjectPerformance.Trend) -> String {
        switch trend {
        case .up:
            return "arrow.up.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }
    
    private func getTrendColor(_ trend: SubjectPerformance.Trend) -> Color {
        switch trend {
        case .up:
            return .green
        case .down:
            return .red
        case .stable:
            return .gray
        }
    }
}

// MARK: - Preview
struct PerformanceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PerformanceView(
                user: User(
                    name: "Alex",
                    avatar: "avatar-1",
                    gradeLevel: 5
                )
            )
        }
    }
} 