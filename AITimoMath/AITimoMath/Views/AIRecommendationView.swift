import SwiftUI

/// A view that displays AI-powered learning recommendations
struct AIRecommendationView: View {
    // User ID for which to show recommendations
    var userId: UUID
    
    // Service instance
    private let aiLearningService = AILearningService.shared
    
    // State properties
    @State private var learningProgress: AILearningProgress?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            headerView
            
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(message: error)
            } else if let progress = learningProgress {
                recommendationsView(progress: progress)
            } else {
                noDataView
            }
        }
        .padding()
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Component Views
    
    /// Header view with title
    private var headerView: some View {
        HStack {
            Text("AI Recommendations")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                loadData()
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        }
        .padding(.bottom, 12)
    }
    
    /// Loading indicator view
    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding()
            Text("Analyzing your learning progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Error message view
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.largeTitle)
                .padding()
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button("Try Again") {
                loadData()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    /// No data available view
    private var noDataView: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .foregroundColor(.gray)
                .font(.largeTitle)
                .padding()
            
            Text("Complete more lessons to get personalized recommendations")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    /// Recommendations content view
    private func recommendationsView(progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Next lesson recommendation
            if !progress.recommendedLessons.isEmpty {
                recommendedLessonsSection(progress: progress)
            }
            
            // Weak areas section
            if !progress.weakAreas.isEmpty {
                weakAreasSection(progress: progress)
            }
            
            // Performance stats section
            performanceStatsSection(progress: progress)
            
            // Ability level indicator
            abilityLevelSection(progress: progress)
        }
    }
    
    /// Recommended lessons section
    private func recommendedLessonsSection(progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Next Lessons")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            ForEach(progress.recommendedLessons.prefix(3), id: \.self) { lessonId in
                // Use a default subject for now since we only have UUID
                let defaultSubject = Lesson.Subject.arithmetic
                
                HStack {
                    Image(systemName: iconForSubject(defaultSubject))
                        .foregroundColor(.blue)
                    
                    Text(subjectTitle(defaultSubject))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Lvl \(difficultyLevel(for: defaultSubject, progress: progress))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue.opacity(0.7))
                        .font(.caption)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Weak areas section
    private func weakAreasSection(progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Areas to Improve")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            ForEach(progress.weakAreas.prefix(3), id: \.subject) { weakArea in
                HStack {
                    Image(systemName: iconForSubject(weakArea.subject))
                        .foregroundColor(.orange)
                    
                    Text(subjectTitle(weakArea.subject))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Progress indicator
                    ProgressView(value: weakArea.conceptScore, total: 1.0)
                        .frame(width: 60)
                    
                    Text("\(Int(weakArea.conceptScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                .padding(12)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Performance stats section
    private func performanceStatsSection(progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Learning Stats")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            HStack(spacing: 16) {
                // Lessons completed
                statView(
                    value: String(progress.lessonHistory.count),
                    label: "Lessons",
                    icon: "book.fill"
                )
                
                // Average accuracy
                statView(
                    value: "\(Int(averageAccuracy(progress) * 100))%",
                    label: "Accuracy",
                    icon: "checkmark.circle.fill"
                )
                
                // Weak areas count
                statView(
                    value: String(progress.weakAreas.count),
                    label: "Weak Areas",
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Ability level section
    private func abilityLevelSection(progress: AILearningProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Current Math Ability")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            VStack {
                // Ability gauge
                HStack {
                    Text("Beginner")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Advanced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        Rectangle()
                            .frame(width: geometry.size.width, height: 8)
                            .opacity(0.2)
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        // Ability indicator
                        Rectangle()
                            .frame(width: min(CGFloat(progress.abilityLevel) / 5.0 * geometry.size.width, geometry.size.width), height: 8)
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                // Ability level description
                Text(abilityLevelDescription(progress.abilityLevel))
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    /// Single stat view
    private func statView(value: String, label: String, icon: String) -> some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.headline)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    /// Load learning progress data
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        // Using a placeholder learningProgress to fix the async issue
        // In a real app, you would use Task and proper async/await
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create a mock learning progress for now
            self.learningProgress = AILearningProgress(userId: self.userId)
            self.isLoading = false
        }
    }
    
    /// Get icon for subject
    private func iconForSubject(_ subject: Lesson.Subject) -> String {
        switch subject {
        case .arithmetic:
            return "number"
        case .numberTheory:
            return "function"
        case .geometry:
            return "triangle"
        case .combinatorics:
            return "square.grid.3x3"
        case .logicalThinking:
            return "brain"
        }
    }
    
    /// Get title for subject
    private func subjectTitle(_ subject: Lesson.Subject) -> String {
        switch subject {
        case .arithmetic:
            return "Arithmetic"
        case .numberTheory:
            return "Number Theory"
        case .geometry:
            return "Geometry"
        case .combinatorics:
            return "Combinatorics"
        case .logicalThinking:
            return "Logical Thinking"
        }
    }
    
    /// Calculate average accuracy from learning progress
    private func averageAccuracy(_ progress: AILearningProgress) -> Float {
        guard !progress.lessonHistory.isEmpty else { return 0 }
        
        let sum = progress.lessonHistory.reduce(0) { $0 + $1.accuracy }
        return sum / Float(progress.lessonHistory.count)
    }
    
    /// Get the difficulty level for a subject
    private func difficultyLevel(for subject: Lesson.Subject, progress: AILearningProgress) -> Int {
        // Find the most recent lesson in this subject
        if let lastLesson = progress.lessonHistory.filter({ $0.subject == subject }).max(by: { $0.completedAt < $1.completedAt }) {
            return lastLesson.nextDifficulty
        }
        
        // Default to difficulty level 1 if no lessons completed in this subject
        return 1
    }
    
    /// Get ability level description
    private func abilityLevelDescription(_ level: Float) -> String {
        switch level {
        case 0..<1.5:
            return "Beginning Math Student"
        case 1.5..<2.5:
            return "Developing Math Skills"
        case 2.5..<3.5:
            return "Proficient Math Student"
        case 3.5..<4.5:
            return "Advanced Math Student"
        default:
            return "Expert Math Student"
        }
    }
}

#Preview {
    AIRecommendationView(userId: UUID())
} 