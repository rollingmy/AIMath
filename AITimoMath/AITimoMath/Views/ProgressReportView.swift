import SwiftUI
import Charts

/// View that displays student's overall progress, learning analytics, and insights
struct ProgressReportView: View {
    // MARK: - Properties
    
    /// The current user
    @ObservedObject var userViewModel: UserViewModel
    
    /// State for AI learning progress
    @State private var learningProgress: AILearningProgress?
    @State private var isLoading = false
    @State private var errorMessage: AlertMessage?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading your progress data...")
                        .padding()
                } else if let progress = learningProgress {
                    // Overall progress
                    overallProgressSection(progress)
                    
                    // Subject breakdown
                    subjectBreakdownSection(progress)
                    
                    // Weak areas
                    weakAreasSection(progress)
                    
                    // Performance trends
                    performanceTrendsSection(progress)
                }
            }
            .padding(.horizontal)
            .navigationTitle("Progress Report")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadProgress)
            .alert(item: $errorMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .background(Color("BackgroundLight"))
    }
    
    /// Load the user's learning progress
    private func loadProgress() {
        isLoading = true
        
        Task {
            do {
                let progress = try await AILearningService.shared.getLearningProgress(userId: userViewModel.id)
                DispatchQueue.main.async {
                    self.learningProgress = progress
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = AlertMessage(error.localizedDescription)
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    /// Overall progress section with summary metrics
    private func overallProgressSection(_ progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Progress")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            HStack(spacing: 16) {
                // Ability level card
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", progress.abilityLevel))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Ability Level")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                // Lessons completed card
                VStack(spacing: 8) {
                    Text("\(userViewModel.completedLessons.count)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Lessons Completed")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            // Progress bar toward daily goal
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Goal Progress: \(userViewModel.completedLessons.count)/\(userViewModel.learningGoal) lessons")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                ProgressView(value: min(Float(userViewModel.completedLessons.count) / Float(userViewModel.learningGoal), 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Subject breakdown section
    private func subjectBreakdownSection(_ progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            if #available(iOS 16.0, *) {
                // Use Swift Charts for iOS 16+
                let scores = progress.subjectScores
                
                // Create a simpler chart without complex styling
                Chart {
                    ForEach(scores) { score in
                        let subjectName = score.subject.displayName
                        let scoreValue = score.score
                        
                        BarMark(
                            x: .value("Subject", subjectName),
                            y: .value("Score", scoreValue)
                        )
                        .foregroundStyle(score.subject.color)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...1)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 12) {
                    ForEach(progress.subjectScores) { score in
                        subjectProgressRow(subject: score.subject, percentage: Double(score.score * 100))
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Subject progress row (fallback for iOS 15)
    private func subjectProgressRow(subject: Lesson.Subject, percentage: Double) -> some View {
        let tempLesson = Lesson(subject: subject)
        let viewModel = LessonViewModel(lesson: tempLesson)
        
        return HStack {
            Image(systemName: viewModel.subjectIconName)
                .foregroundColor(subject.color)
                .font(.system(size: 22))
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading) {
                Text(subject.displayName)
                    .font(.headline)
                
                ProgressView(value: percentage / 100)
                    .tint(subject.color)
                    .frame(height: 8)
            }
            
            Spacer()
            
            Text("\(Int(percentage))%")
                .font(.headline)
                .foregroundColor(subject.color)
        }
        .padding(.vertical, 4)
    }
    
    /// Weak areas section with improvement suggestions
    private func weakAreasSection(_ progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas for Improvement")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            if progress.weakAreas.isEmpty {
                Text("Great job! No weak areas identified yet. Complete more lessons to get personalized suggestions.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // Convert to array with identifiable indices
                let identifiableWeakAreas = progress.weakAreas.enumerated().map { (index, area) in 
                    (id: index, area: area)
                }
                
                ForEach(identifiableWeakAreas, id: \.id) { pair in
                    weakAreaRow(AILearningWeakArea(
                        id: UUID(),
                        subject: pair.area.subject,
                        conceptScore: pair.area.conceptScore,
                        conceptName: "\(pair.area.subject.displayName) Concept",
                        completedAt: pair.area.lastPracticed
                    ))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Individual weak area row
    private func weakAreaRow(_ weakArea: AILearningWeakArea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(weakArea.subject.color)
                    .frame(width: 12, height: 12)
                
                Text(weakArea.conceptName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("DarkGray"))
                
                Spacer()
                
                Text("\(Int(weakArea.conceptScore * 100))%")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(weakArea.subject.color)
            }
            
            Text("Practice more \(weakArea.subject.displayName) problems focusing on \(weakArea.conceptName) to improve your skills.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
            
            // Recommendation button
            Button(action: {
                // In a real app, this would navigate to practice for this specific concept
            }) {
                Text("Practice This Concept")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(weakArea.subject.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    /// Performance trends section
    private func performanceTrendsSection(_ progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            if progress.lessonHistory.isEmpty {
                Text("Complete more lessons to see your performance trends over time.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding()
            } else if #available(iOS 16.0, *) {
                // Performance chart for iOS 16+
                let recentLessons = Array(progress.lessonHistory.prefix(10))
                
                // Simple chart without complex annotations
                Chart {
                    ForEach(recentLessons.indices, id: \.self) { idx in
                        let lesson = recentLessons[idx]
                        let xValue = progress.lessonHistory.count - idx
                        let yValue = lesson.accuracy
                        
                        LineMark(
                            x: .value("Lesson", xValue),
                            y: .value("Accuracy", yValue)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...1)
            } else {
                // Fallback visual for iOS 15
                VStack(spacing: 16) {
                    let recentLessons = Array(progress.lessonHistory.prefix(5))
                    
                    // Create AILearningLessonCompletion objects from AILearningProgress.LessonProgress
                    let convertedLessons = recentLessons.map { lessonProgress -> AILearningLessonCompletion in
                        return AILearningLessonCompletion(
                            id: lessonProgress.lessonId,
                            subject: lessonProgress.subject,
                            difficulty: lessonProgress.nextDifficulty,
                            nextDifficulty: lessonProgress.nextDifficulty,
                            accuracy: lessonProgress.accuracy,
                            completedAt: lessonProgress.completedAt,
                            responseTimeAvg: lessonProgress.responseTime
                        )
                    }
                    
                    ForEach(convertedLessons.indices, id: \.self) { idx in
                        performanceHistoryRow(convertedLessons[idx])
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Individual performance history row
    private func performanceHistoryRow(_ lesson: AILearningLessonCompletion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.subject.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("DarkGray"))
                
                Text("Difficulty: \(difficultyName(for: lesson.difficulty))")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(lesson.accuracy * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(lesson.accuracy >= 0.7 ? .green : (lesson.accuracy >= 0.4 ? .orange : .red))
                
                Text(lesson.completedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // Add a helper function to get the difficulty name
    private func difficultyName(for difficulty: Int) -> String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        case 4: return "Expert"
        default: return "Unknown"
        }
    }
}

// MARK: - Preview
struct ProgressReportView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            name: "Test Student",
            avatar: "avatar-1",
            gradeLevel: 5
        )
        
        return NavigationView {
            ProgressReportView(userViewModel: UserViewModel(user: user))
        }
    }
} 