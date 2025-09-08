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
    
    // Function to load recommended lessons
    private func loadRecommendedLessons() {
        // This would normally call an API or load from database
        // For this implementation, we'll create some sample data based on the timo_questions.json
        isLoading = true
        
        // Simulating network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create sample lessons based on question categories from the json file
            self.recommendedLessons = subjects.map { subject, icon in
                return Lesson(
                    userId: user.id,
                    subject: getSubjectEnum(from: subject)
                )
            }
            
            self.isLoading = false
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
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Top Section
                topSection
                
                // MARK: - Middle Section (Subject Categories)
                middleSection
                
                // MARK: - Bottom Section (Progress & Achievements)
                bottomSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .navigationBarItems(trailing: profileButton)
        .onAppear {
            loadRecommendedLessons()
        }
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 15) {
            // User avatar and greeting
            HStack {
                Image(user.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
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
                    
                    VStack {
                        Text("\(user.dailyCompletedQuestions)/\(user.dailyGoal)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // AI recommended lesson
            if isLoading {
                ProgressView()
                    .frame(height: 100)
            } else if let firstRecommendation = recommendedLessons.first {
                NavigationLink(destination: LessonDetailView(lesson: firstRecommendation, user: user)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text("AI Recommended")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(getSubjectDisplayName(firstRecommendation.subject))
                            .font(.headline)
                        
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
                            
                            Text("Start Now")
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
            
            // Start Today's Practice Button
            Button(action: {
                // Action to start today's practice
            }) {
                Text("Start Today's Practice")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding(.bottom, 10)
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
    
    // MARK: - Middle Section (Subject Categories)
    private var middleSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Subjects")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 15)
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
        .padding(.bottom, 10)
    }
    
    // MARK: - Bottom Section (Progress & Achievements)
    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Progress")
                .font(.headline)
            
            // Progress chart (simplified for example)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(subjects, id: \.0) { subject, _ in
                    HStack {
                        Text(subject)
                            .font(.caption)
                            .frame(width: 120, alignment: .leading)
                        
                        // Calculate actual progress based on user data
                        let progress = getProgressForSubject(subject)
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(height: 10)
                                .foregroundColor(Color(.systemGray5))
                                .cornerRadius(5)
                            
                            Rectangle()
                                .frame(width: CGFloat(progress) * 200, height: 10)
                                .foregroundColor(.blue)
                                .cornerRadius(5)
                        }
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .frame(width: 40)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Review Mistakes Button
            NavigationLink(destination: MistakesReviewView(user: user)) {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                    
                    Text("Review Mistakes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Achievements Section
            Text("Achievements")
                .font(.headline)
                .padding(.top, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(1...5, id: \.self) { i in
                        VStack {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.yellow)
                            
                            Text("Achievement \(i)")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    

    // Helper function to calculate actual progress for a subject
    private func getProgressForSubject(_ subject: String) -> Double {
        // For now, we'll calculate based on daily completed questions vs goal
        // In a real app, this would come from the user's lesson history and performance data
        
        let totalGoal = user.dailyGoal
        let completed = user.dailyCompletedQuestions
        
        if totalGoal == 0 {
            return 0.0
        }
        
        // Calculate progress as a percentage of daily goal completion
        let progress = Double(completed) / Double(totalGoal)
        
        // Cap progress at 100% and ensure it's not negative
        return max(0.0, min(1.0, progress))
    }
    // MARK: - Profile Button
    private var profileButton: some View {
        NavigationLink(destination: SettingsView(user: user)) {
            Image(systemName: "gear")
                .font(.system(size: 22))
                .foregroundColor(.blue)
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
