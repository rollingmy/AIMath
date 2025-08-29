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
    
    // Load performance data
    private func loadPerformanceData() {
        isLoading = true
        
        // This would normally load real performance data from a database
        // For this implementation, we'll create some mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var performance: [SubjectPerformance] = []
            
            // Generate random performance data for each subject
            for subject in subjects {
                let accuracy = Double.random(in: 60.0...95.0)
                let trend: SubjectPerformance.Trend
                
                // Randomly assign trend direction
                let trendValue = Int.random(in: 0...2)
                if trendValue == 0 {
                    trend = .up
                } else if trendValue == 1 {
                    trend = .down
                } else {
                    trend = .stable
                }
                
                performance.append(SubjectPerformance(
                    subject: subject,
                    accuracy: accuracy,
                    trend: trend
                ))
            }
            
            // Sort by accuracy (lowest first for improvement focus)
            self.subjectPerformance = performance.sorted(by: { $0.accuracy < $1.accuracy })
            
            // Generate weaknesses based on lowest accuracy subjects
            let lowestPerforming = subjectPerformance.prefix(2)
            
            var aiWeaknesses: [String] = []
            
            for subject in lowestPerforming {
                if subject.subject == "Logical Thinking" {
                    aiWeaknesses.append("Pattern Recognition and Logical Inference")
                } else if subject.subject == "Arithmetic" {
                    aiWeaknesses.append("Fractions and Division")
                } else if subject.subject == "Number Theory" {
                    aiWeaknesses.append("Prime Factorization and LCM/GCD")
                } else if subject.subject == "Geometry" {
                    aiWeaknesses.append("Area Calculation and Spatial Reasoning")
                } else if subject.subject == "Combinatorics" {
                    aiWeaknesses.append("Probability and Counting Principles")
                }
            }
            
            // Add a few more general weaknesses
            aiWeaknesses.append("Word Problem Comprehension")
            aiWeaknesses.append("Multi-Step Problems")
            
            self.weaknesses = aiWeaknesses
            self.isLoading = false
        }
    }
    
    var body: some View {
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
                        
                        // Mock progress chart
                        ZStack(alignment: .leading) {
                            // Create a grid background
                            VStack(spacing: 0) {
                                ForEach(0..<4) { _ in
                                    Divider()
                                    Spacer()
                                }
                            }
                            
                            // Create line chart with random data points
                            GeometryReader { geometry in
                                Path { path in
                                    // Starting point
                                    let startX = 0
                                    let startY = Int.random(in: 100...Int(geometry.size.height - 50))
                                    path.move(to: CGPoint(x: startX, y: startY))
                                    
                                    // Generate random points
                                    let numberOfPoints = 8
                                    let pointWidth = Int(geometry.size.width) / numberOfPoints
                                    
                                    for i in 1...numberOfPoints {
                                        let nextX = i * pointWidth
                                        let nextY = Int.random(in: 20...Int(geometry.size.height - 20))
                                        path.addLine(to: CGPoint(x: nextX, y: nextY))
                                    }
                                }
                                .stroke(Color.blue, lineWidth: 2)
                                
                                // Add data points as circles
                                ForEach(0..<8, id: \.self) { i in
                                    let pointX = i * (Int(geometry.size.width) / 8)
                                    let pointY = Int.random(in: 20...Int(geometry.size.height - 20))
                                    
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                        .position(x: CGFloat(pointX), y: CGFloat(pointY))
                                }
                            }
                        }
                        .frame(height: 200)
                        .padding(.vertical)
                        
                        // X-axis labels
                        HStack {
                            Text(getStartDateLabel())
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(getEndDateLabel())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // MARK: - Subject Performance
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Subject Performance")
                            .font(.headline)
                        
                        ForEach(subjectPerformance) { subject in
                            HStack {
                                // Subject name
                                Text(subject.subject)
                                    .font(.subheadline)
                                    .frame(width: 120, alignment: .leading)
                                
                                // Progress bar
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(height: 10)
                                        .foregroundColor(Color(.systemGray5))
                                        .cornerRadius(5)
                                    
                                    Rectangle()
                                        .frame(width: CGFloat(subject.accuracy / 100.0) * 180, height: 10)
                                        .foregroundColor(getAccuracyColor(subject.accuracy))
                                        .cornerRadius(5)
                                }
                                
                                // Accuracy percentage
                                Text("\(Int(subject.accuracy))%")
                                    .font(.caption)
                                    .frame(width: 40)
                                
                                // Trend indicator
                                Image(systemName: getTrendIcon(subject.trend))
                                    .foregroundColor(getTrendColor(subject.trend))
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // MARK: - AI-Detected Weaknesses
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AI-Detected Improvement Areas")
                            .font(.headline)
                        
                        ForEach(weaknesses, id: \.self) { weakness in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .frame(width: 20)
                                
                                Text(weakness)
                                    .font(.subheadline)
                                
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            
                            if weakness != weaknesses.last {
                                Divider()
                            }
                        }
                        
                        // Improvement session button
                        Button(action: {
                            // Action to start improvement session
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Start Improvement Session")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Performance Analytics")
        .onAppear {
            loadPerformanceData()
        }
    }
    
    // MARK: - Helper Functions
    
    // Get color based on accuracy
    private func getAccuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 80 {
            return .green
        } else if accuracy >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Get icon for trend direction
    private func getTrendIcon(_ trend: SubjectPerformance.Trend) -> String {
        switch trend {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .stable:
            return "arrow.forward"
        }
    }
    
    // Get color for trend
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
    
    // Get formatted date for x-axis start label
    private func getStartDateLabel() -> String {
        let calendar = Calendar.current
        var date = Date()
        
        switch selectedTimeRange {
        case .week:
            date = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            date = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .all:
            date = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // Get formatted date for x-axis end label
    private func getEndDateLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
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