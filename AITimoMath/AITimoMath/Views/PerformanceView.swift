import SwiftUI
import Charts

/// View displaying the user's performance analytics
struct PerformanceView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State for filter selection
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedSubject: Lesson.Subject? = nil
    
    // Enum for time frame selection
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case allTime = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .allTime: return 365 // Just a large number
            }
        }
    }
    
    // For backward compatibility with simple preview methods
    init(user: User) {
        self.userViewModel = UserViewModel(user: user)
    }
    
    // For use with the ViewModel
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Time frame selector
                    timeFrameSelector
                    
                    // Performance overview
                    overviewSection
                    
                    // Subject filter
                    subjectFilterSection
                    
                    // Performance charts
                    chartsSection
                    
                    // Recent lessons
                    recentLessonsSection
                }
                .padding()
            }
            .navigationTitle("Performance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Time frame selector
    private var timeFrameSelector: some View {
        Picker("Time Frame", selection: $selectedTimeFrame) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Text(timeFrame.rawValue).tag(timeFrame)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.bottom, 8)
    }
    
    // Performance overview section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Lessons completed
                statCard(
                    title: "Lessons",
                    value: "\(filteredLessons.count)",
                    icon: "book.fill",
                    color: .blue
                )
                
                // Average accuracy
                statCard(
                    title: "Accuracy",
                    value: String(format: "%.0f%%", averageAccuracy),
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // Questions answered
                statCard(
                    title: "Questions",
                    value: "\(totalQuestionsAnswered)",
                    icon: "questionmark.circle.fill",
                    color: .purple
                )
            }
            .frame(height: 100)
        }
    }
    
    // Subject filter section
    private var subjectFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Subject")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // All subjects button
                    Button(action: {
                        selectedSubject = nil
                    }) {
                        Text("All")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedSubject == nil ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedSubject == nil ? .white : .primary)
                            .cornerRadius(20)
                    }
                    
                    // Subject filter buttons
                    ForEach([Lesson.Subject.arithmetic, .geometry, .numberTheory, .logicalThinking, .combinatorics], id: \.self) { subject in
                        Button(action: {
                            selectedSubject = subject
                        }) {
                            Text(formatSubject(subject))
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedSubject == subject ? subjectColor(subject) : Color(.systemGray5))
                                .foregroundColor(selectedSubject == subject ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    // Charts section
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Trends")
                .font(.headline)
            
            // Accuracy chart
            VStack(alignment: .leading, spacing: 10) {
                Text("Accuracy Over Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(accuracyData, id: \.day) { item in
                            LineMark(
                                x: .value("Day", item.day),
                                y: .value("Accuracy", item.accuracy)
                            )
                            .foregroundStyle(Color.blue)
                            
                            PointMark(
                                x: .value("Day", item.day),
                                y: .value("Accuracy", item.accuracy)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...100)
                } else {
                    // Fallback for iOS < 16
                    Text("Charts available in iOS 16 and later")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Subject performance chart
            VStack(alignment: .leading, spacing: 10) {
                Text("Performance by Subject")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(subjectData, id: \.subject) { item in
                            BarMark(
                                x: .value("Subject", formatSubject(item.subject)),
                                y: .value("Accuracy", item.accuracy)
                            )
                            .foregroundStyle(subjectColor(item.subject))
                        }
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...100)
                } else {
                    // Fallback for iOS < 16
                    Text("Charts available in iOS 16 and later")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    // Recent lessons section
    private var recentLessonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Lessons")
                .font(.headline)
            
            if filteredLessons.isEmpty {
                Text("No lessons completed yet for the selected filters.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                // Recent lessons list
                ForEach(filteredLessons.prefix(5), id: \.id) { lesson in
                    lessonRow(lesson)
                }
            }
        }
    }
    
    // Helper Views
    
    // Stat card view
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // Lesson row view
    private func lessonRow(_ lesson: Lesson) -> some View {
        HStack {
            // Subject icon
            Circle()
                .fill(subjectColor(lesson.subject))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(formatSubject(lesson.subject).prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // Lesson details
            VStack(alignment: .leading, spacing: 4) {
                Text(formatSubject(lesson.subject))
                    .font(.headline)
                
                Text("Completed \(formatDate(lesson.completedAt ?? Date()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Accuracy
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(lesson.accuracy * 100))%")
                    .font(.headline)
                    .foregroundColor(accuracyColor(Double(lesson.accuracy)))
                
                Text("\(lesson.questions.count) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // Helper Methods
    
    // Format subject name
    private func formatSubject(_ subject: Lesson.Subject) -> String {
        switch subject {
        case .logicalThinking:
            return "Logical Thinking"
        case .arithmetic:
            return "Arithmetic"
        case .numberTheory:
            return "Number Theory"
        case .geometry:
            return "Geometry"
        case .combinatorics:
            return "Combinatorics"
        }
    }
    
    // Get color for a subject
    private func subjectColor(_ subject: Lesson.Subject) -> Color {
        switch subject {
        case .logicalThinking:
            return .purple
        case .arithmetic:
            return .blue
        case .numberTheory:
            return .green
        case .geometry:
            return .orange
        case .combinatorics:
            return .red
        }
    }
    
    // Get color based on accuracy
    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Computed Properties
    
    // Get lessons filtered by time frame and subject
    private var filteredLessons: [Lesson] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeFrame.days, to: Date()) ?? Date()
        
        // Convert lesson IDs to mock lessons for display
        let allLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        return allLessons.filter { lesson in
            if let completedAt = lesson.completedAt, completedAt > cutoffDate {
                if let selectedSubject = selectedSubject {
                    return lesson.subject == selectedSubject
                }
                return true
            }
            return false
        }.sorted(by: { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) })
    }
    
    // Average accuracy for filtered lessons
    private var averageAccuracy: Double {
        guard !filteredLessons.isEmpty else { return 0 }
        let sum = filteredLessons.reduce(0.0) { $0 + Double($1.accuracy) }
        return (sum / Double(filteredLessons.count)) * 100
    }
    
    // Total questions answered
    private var totalQuestionsAnswered: Int {
        filteredLessons.reduce(0) { $0 + $1.questions.count }
    }
    
    // Data for accuracy chart
    private var accuracyData: [(day: String, accuracy: Double)] {
        let calendar = Calendar.current
        let today = Date()
        
        // Create date formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        // Calculate data points based on time frame
        var dataPoints: [(day: String, accuracy: Double)] = []
        
        // Group lessons by day
        let daysToShow = selectedTimeFrame == .week ? 7 : (selectedTimeFrame == .month ? 14 : 30)
        
        for dayOffset in (0..<daysToShow).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Filter lessons for this day
            let dayLessons = filteredLessons.filter { lesson in
                if let completedAt = lesson.completedAt,
                   completedAt >= dayStart && completedAt < dayEnd {
                    return true
                }
                return false
            }
            
            // Calculate accuracy for this day
            let dayAccuracy: Double
            if !dayLessons.isEmpty {
                let sum = dayLessons.reduce(0.0) { $0 + Double($1.accuracy) }
                dayAccuracy = (sum / Double(dayLessons.count)) * 100
            } else {
                dayAccuracy = 0
            }
            
            // Format date for display
            let dayString = formatter.string(from: date)
            
            dataPoints.append((day: dayString, accuracy: dayAccuracy))
        }
        
        return dataPoints
    }
    
    // Data for subject chart
    private var subjectData: [(subject: Lesson.Subject, accuracy: Double)] {
        var subjectAccuracy: [Lesson.Subject: (sum: Double, count: Int)] = [:]
        
        // Group by subject
        for lesson in filteredLessons {
            let currentValue = subjectAccuracy[lesson.subject] ?? (sum: 0, count: 0)
            subjectAccuracy[lesson.subject] = (sum: currentValue.sum + Double(lesson.accuracy), count: currentValue.count + 1)
        }
        
        // Calculate average for each subject
        var result: [(subject: Lesson.Subject, accuracy: Double)] = []
        
        for subject in [Lesson.Subject.arithmetic, .geometry, .numberTheory, .logicalThinking, .combinatorics] {
            if let data = subjectAccuracy[subject], data.count > 0 {
                result.append((subject: subject, accuracy: (data.sum / Double(data.count)) * 100))
            } else {
                result.append((subject: subject, accuracy: 0))
            }
        }
        
        return result
    }
    
    // Helper method to convert lesson IDs to mock lessons
    private func getMockLessonsFromIds(_ lessonIds: [UUID]) -> [Lesson] {
        // In a real app, we would fetch these from a database or service
        // For now, we'll create mock lessons
        var mockLessons: [Lesson] = []
        
        for (index, id) in lessonIds.enumerated() {
            let subject: Lesson.Subject
            switch index % 5 {
            case 0: subject = .arithmetic
            case 1: subject = .geometry
            case 2: subject = .numberTheory
            case 3: subject = .logicalThinking
            default: subject = .combinatorics
            }
            
            // Create random responses with some mistakes
            var responses: [Lesson.QuestionResponse] = []
            let questionIds = (0..<5).map { _ in UUID() }
            
            for qId in questionIds {
                responses.append(Lesson.QuestionResponse(
                    questionId: qId,
                    isCorrect: Bool.random(),
                    responseTime: Double.random(in: 10...60),
                    answeredAt: Date().addingTimeInterval(-Double.random(in: 0...(Double(selectedTimeFrame.days) * 86400)))
                ))
            }
            
            let lesson = Lesson(
                id: id,
                userId: userViewModel.user.id,
                subject: subject,
                difficulty: Int.random(in: 1...3),
                questions: questionIds,
                responses: responses,
                accuracy: Float.random(in: 0.5...1.0),
                responseTime: Double.random(in: 100...600),
                startedAt: Date().addingTimeInterval(-3600),
                completedAt: Date().addingTimeInterval(-Double.random(in: 0...(Double(selectedTimeFrame.days) * 86400))),
                status: .completed
            )
            
            mockLessons.append(lesson)
        }
        
        return mockLessons
    }
}

#Preview {
    let user = User(
        name: "Alex",
        avatar: "avatar-1",
        gradeLevel: 3
    )
    PerformanceView(user: user)
} 