import SwiftUI

struct LessonSummaryView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let averageResponseTime: Double
    let incorrectQuestions: [Question]
    let nextLessonDifficulty: String
    
    @Binding var user: User
    @Environment(\.presentationMode) var presentationMode
    
    // Calculate accuracy percentage
    private var accuracyPercentage: Double {
        Double(correctAnswers) / Double(totalQuestions) * 100.0
    }
    
    // Helper to determine color based on performance
    private func getAccuracyColor() -> Color {
        if accuracyPercentage >= 80 {
            return .green
        } else if accuracyPercentage >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Helper to get message based on performance
    private func getPerformanceMessage() -> String {
        if accuracyPercentage >= 80 {
            return "Excellent work! Keep it up!"
        } else if accuracyPercentage >= 60 {
            return "Good job! Some room for improvement."
        } else {
            return "Keep practicing to improve your score."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // MARK: - Accuracy Score
                VStack(spacing: 10) {
                    Text("Lesson Completed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(accuracyPercentage / 100.0))
                            .stroke(getAccuracyColor(), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(accuracyPercentage))%")
                                .font(.system(size: 36, weight: .bold))
                            
                            Text("Accuracy")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(getPerformanceMessage())
                        .font(.headline)
                        .foregroundColor(getAccuracyColor())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // MARK: - Response Time Analysis
                VStack(alignment: .leading, spacing: 10) {
                    Text("Response Time")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        
                        Text("Average: \(String(format: "%.1f", averageResponseTime)) seconds")
                            .font(.subheadline)
                    }
                    
                    // Mock response time graph
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(height: 35)
                            .foregroundColor(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<totalQuestions, id: \.self) { i in
                                // Simulate random response times for visualization
                                let randomHeight = Double.random(in: 0.3...1.0)
                                
                                Rectangle()
                                    .frame(height: CGFloat(randomHeight * 30))
                                    .foregroundColor(.blue)
                                    .cornerRadius(2)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
                
                // MARK: - Incorrect Answers
                VStack(alignment: .leading, spacing: 10) {
                    Text("Areas to Improve")
                        .font(.headline)
                    
                    if incorrectQuestions.isEmpty {
                        Text("Perfect score! No incorrect answers.")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.vertical, 5)
                    } else {
                        ForEach(incorrectQuestions.prefix(3)) { question in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(question.questionText.split(separator: "\n").first?.description ?? "")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(question.hint?.split(separator: "\n").first?.description ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 5)
                            
                            if question.id != incorrectQuestions.prefix(3).last?.id {
                                Divider()
                            }
                        }
                        
                        if incorrectQuestions.count > 3 {
                            Text("+ \(incorrectQuestions.count - 3) more questions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 5)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
                
                // MARK: - Next Lesson Difficulty
                VStack(alignment: .leading, spacing: 10) {
                    Text("AI Recommendation")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Next lesson difficulty adjusted to:")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Spacer()
                        
                        Text(nextLessonDifficulty)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    
                    Text("Based on your performance, the AI has recommended this difficulty level for your next lesson.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
                
                // MARK: - Action Buttons
                VStack(spacing: 15) {
                    // Retry incorrect questions button (enabled only if there are incorrect questions)
                    Button(action: {
                        // In a real app, this would navigate to review incorrect questions
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry Incorrect Questions")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(incorrectQuestions.isEmpty ? Color.gray.opacity(0.3) : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(incorrectQuestions.isEmpty)
                    
                    // Continue to dashboard button
                    Button(action: {
                        // Update user stats
                        user.dailyCompletedQuestions += totalQuestions
                        
                        // Dismiss this view
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "house")
                            Text("Continue to Dashboard")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct LessonSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some mock incorrect questions
        let questionLoader = QuestionLoaderService()
        let mockIncorrectQuestions = questionLoader.getQuestions(
            subject: "Arithmetic",
            difficulty: "Medium",
            count: 3
        )
        
        return LessonSummaryView(
            correctAnswers: 7,
            totalQuestions: 10,
            averageResponseTime: 8.5,
            incorrectQuestions: mockIncorrectQuestions,
            nextLessonDifficulty: "Medium",
            user: .constant(User(
                name: "Alex",
                avatar: "avatar-1",
                gradeLevel: 5,
                dailyGoal: 10,
                dailyCompletedQuestions: 5
            ))
        )
    }
} 