import SwiftUI

struct DashboardView: View {
    @ObservedObject var user: User
    @State private var recommendedLessons: [Lesson] = []
    @State private var isLoading = true
    
    // Sample subject categories
    private let subjects = [
        ("Logical Thinking", "brain"),
        ("Arithmetic", "plus.slash.minus"),
        ("Number Theory", "number"),
        ("Geometry", "triangle"),
        ("Combinatorics", "die.face.5")
    ]
    
    // Function to load recommended lessons based on performance data
    private func loadRecommendedLessons() {
        isLoading = true
        
        Task {
            do {
                // Get user's performance data to identify weak areas
                let subjectPerformance = try await PerformanceService.shared.calculateSubjectPerformance(userId: user.id)
                let weakAreas = try await PerformanceService.shared.identifyWeakAreas(userId: user.id)
                
                await MainActor.run {
                    var recommendations: [Lesson] = []
                    
                    // If user has completed lessons, recommend based on weak areas
                    if !subjectPerformance.isEmpty {
                        // Sort subjects by accuracy (lowest first) to prioritize weak areas
                        let sortedSubjects = subjectPerformance.values.sorted { $0.accuracy < $1.accuracy }
                        
                        // Recommend the weakest performing subjects first
                        for subjectData in sortedSubjects.prefix(3) {
                            let subject = getSubjectEnum(from: subjectData.subject)
                            recommendations.append(Lesson(
                                userId: user.id,
                                subject: subject
                            ))
                        }
                    }
                    
                    // If no performance data yet, or less than 3 recommendations, fill with default order
                    if recommendations.count < 3 {
                        let remainingSubjects = subjects.compactMap { subjectName, _ in
                            let subject = getSubjectEnum(from: subjectName)
                            // Only add if not already in recommendations
                            if !recommendations.contains(where: { $0.subject == subject }) {
                                return Lesson(userId: user.id, subject: subject)
                            }
                            return nil
                        }
                        
                        recommendations.append(contentsOf: remainingSubjects.prefix(3 - recommendations.count))
                    }
                    
                    self.recommendedLessons = recommendations
                    self.isLoading = false
                }
            } catch {
                // Fallback to default behavior if performance data loading fails
                await MainActor.run {
                    self.recommendedLessons = subjects.map { subject, icon in
                        return Lesson(
                            userId: user.id,
                            subject: getSubjectEnum(from: subject)
                        )
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    // Helper function to convert string to Subject enum
    private func getSubjectEnum(from subjectString: String) -> Lesson.Subject {
        switch subjectString {
        case "Logical Thinking":
            return .logicalThinking
        case "Arithmetic":
            return .arithmetic
        case "Number Theory":
            return .numberTheory
        case "Geometry":
            return .geometry
        case "Combinatorics":
            return .combinatorics
        default:
            return .logicalThinking
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerSection
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - User Info and Daily Goal
                    userInfoSection
                    
                    // MARK: - AI Recommended Section
                    aiRecommendedSection
                    
                    // MARK: - Start Today's Practice Button
                    startPracticeButton
                    
                    // MARK: - Subjects Section
                    subjectsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for bottom navigation
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadRecommendedLessons()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: SettingsView(user: user)) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(8)
                }
                .background(Color(.systemGray6))
                .clipShape(Circle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(user.name)!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Grade \(user.gradeLevel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Daily goal progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(user.dailyCompletedQuestions) / CGFloat(user.dailyGoal), 1.0))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(user.dailyCompletedQuestions)/\(user.dailyGoal)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - AI Recommended Section
    private var aiRecommendedSection: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if let firstRecommendation = recommendedLessons.first {
                NavigationLink(destination: LessonDetailView(lesson: firstRecommendation, user: user)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text("AI Recommended")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(getSubjectDisplayName(firstRecommendation.subject))
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("AI recommended based on your progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(getSubjectDisplayName(firstRecommendation.subject))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            
                            Text("Difficulty \(firstRecommendation.difficulty)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("AI Recommended")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Start Today's Practice Button
    private var startPracticeButton: some View {
        Group {
            if let firstRecommendation = recommendedLessons.first {
                NavigationLink(destination: LessonDetailView(lesson: firstRecommendation, user: user)) {
                    Text("Start Today's Practice")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {}) {
                    Text("Start Today's Practice")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(10)
                }
                .disabled(true)
            }
        }
    }
    
    // Helper function to get display name for subject
    private func getSubjectDisplayName(_ subject: Lesson.Subject) -> String {
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
    
    // MARK: - Subjects Section
    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Subjects")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15)
            ], spacing: 15) {
                ForEach(subjects.indices, id: \.self) { index in
                    NavigationLink(destination: SubjectLessonsView(
                        subject: subjects[index].0,
                        iconName: subjects[index].1,
                        user: user
                    )) {
                        VStack(spacing: 10) {
                            Image(systemName: subjects[index].1)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                            
                            Text(subjects[index].0)
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(
            user: User(
                name: "Alex",
                avatar: "avatar-1",
                gradeLevel: 5,
                dailyGoal: 10,
                dailyCompletedQuestions: 4
            )
        )
    }
} 
