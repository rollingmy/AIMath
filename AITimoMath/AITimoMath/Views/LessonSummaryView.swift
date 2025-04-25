import SwiftUI

/// View that displays the lesson summary and performance statistics after a lesson is completed
struct LessonSummaryView: View {
    // MARK: - Properties
    
    /// The completed lesson
    let lesson: Lesson
    
    /// The current user
    @ObservedObject var userViewModel: UserViewModel
    
    /// Results for each question (correct/incorrect)
    let questionResults: [Bool]
    
    /// Response times for each question
    let responseTimes: [TimeInterval]
    
    /// Closure to dismiss the view
    let onDismiss: () -> Void
    
    /// View model for the lesson
    private let lessonViewModel: LessonViewModel
    
    /// Initialize with required parameters
    init(lesson: Lesson, userViewModel: UserViewModel, questionResults: [Bool], responseTimes: [TimeInterval], onDismiss: @escaping () -> Void) {
        self.lesson = lesson
        self.userViewModel = userViewModel
        self.questionResults = questionResults
        self.responseTimes = responseTimes
        self.onDismiss = onDismiss
        self.lessonViewModel = LessonViewModel(lesson: lesson)
    }
    
    // MARK: - Computed Properties
    
    /// Accuracy percentage
    private var accuracyPercentage: Int {
        let correctCount = questionResults.filter { $0 }.count
        return Int((Float(correctCount) / Float(questionResults.count)) * 100)
    }
    
    /// Average response time in seconds
    private var averageResponseTime: Double {
        guard !responseTimes.isEmpty else { return 0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    /// List of incorrect questions (indices)
    private var incorrectQuestionIndices: [Int] {
        return questionResults.enumerated()
            .filter { !$0.element }
            .map { $0.offset }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Lesson completion header
                completionHeader
                
                // Performance metrics
                performanceMetricsSection
                
                // Common mistakes section
                if !incorrectQuestionIndices.isEmpty {
                    mistakesSection
                }
                
                // Next steps section
                nextStepsSection
                
                // Action buttons
                actionButtons
            }
            .padding()
        }
        .background(Color("BackgroundLight"))
    }
    
    // MARK: - Component Views
    
    /// Lesson completion header with subject and confetti animation
    private var completionHeader: some View {
        VStack(spacing: 16) {
            // Celebration icon and text
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.bottom, 8)
            
            Text("Lesson Completed!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            // Subject and difficulty info
            Text("\(lessonViewModel.subjectDisplayName) - \(lessonViewModel.difficultyName) Level")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Performance metrics section with accuracy and speed
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            HStack(spacing: 16) {
                // Accuracy metric
                VStack {
                    Text("\(accuracyPercentage)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(accuracyColor)
                    
                    Text("Accuracy")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                // Response time metric
                VStack {
                    Text(String(format: "%.1f", averageResponseTime))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Avg. Seconds")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            // Questions breakdown
            HStack {
                Text("Total Questions: \(questionResults.count)")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Correct: \(questionResults.filter { $0 }.count)")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Incorrect: \(questionResults.filter { !$0 }.count)")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Incorrect answers section
    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Common Mistakes")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            VStack(spacing: 16) {
                // In a real implementation, we would fetch the actual questions
                // using the question IDs stored in lesson.questions
                // For now, we'll just show placeholders
                ForEach(incorrectQuestionIndices, id: \.self) { index in
                    mistakePlaceholderRow(index: index)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Placeholder for incorrect question row
    private func mistakePlaceholderRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question \(index + 1)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("DarkGray"))
            
            Text("This question was answered incorrectly.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    /// Next steps section with AI recommendations
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Steps")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            VStack(alignment: .leading, spacing: 12) {
                // AI recommendation based on performance
                if accuracyPercentage < 50 {
                    nextStepRow(
                        icon: "arrow.counterclockwise",
                        title: "Retry this lesson",
                        description: "Practice makes perfect! Try these questions again to improve."
                    )
                } else if accuracyPercentage < 80 {
                    nextStepRow(
                        icon: "books.vertical",
                        title: "Practice similar questions",
                        description: "You're on the right track! Some additional practice will help."
                    )
                } else {
                    nextStepRow(
                        icon: "arrow.up.right",
                        title: "Move to the next level",
                        description: "Great job! You're ready for more challenging questions."
                    )
                }
                
                // Common next step for all students
                nextStepRow(
                    icon: "chart.bar",
                    title: "Review your progress",
                    description: "Check your analytics to see improvement over time."
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Individual next step recommendation row
    private func nextStepRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("DarkGray"))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    /// Action buttons section with practice and continue options
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Continue button
            Button(action: {
                onDismiss()
            }) {
                Text("Return to Dashboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            // Review mistakes button (only if there were mistakes)
            if accuracyPercentage < 100 {
                NavigationLink(destination: ReviewMistakesView(userViewModel: userViewModel)) {
                    Text("Review Mistakes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Properties
    
    /// Color for the accuracy percentage based on performance
    private var accuracyColor: Color {
        switch accuracyPercentage {
        case 0..<50:
            return .red
        case 50..<80:
            return .orange
        default:
            return .green
        }
    }
}

// MARK: - Preview
struct LessonSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            name: "Test Student",
            avatar: "avatar-1",
            gradeLevel: 5
        )
        let userViewModel = UserViewModel(user: user)
        
        let lesson = Lesson(userId: userViewModel.id, subject: .arithmetic)
        
        return LessonSummaryView(
            lesson: lesson,
            userViewModel: userViewModel,
            questionResults: [true, false],
            responseTimes: [4.5, 6.5],
            onDismiss: {}
        )
    }
} 