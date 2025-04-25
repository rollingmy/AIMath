import SwiftUI

/// Main dashboard view displaying user progress, AI recommendations, and lesson categories
struct DashboardView: View {
    // User information
    @ObservedObject var userViewModel: UserViewModel
    
    // State for AI recommendations
    @State private var learningProgress: AILearningProgress?
    @State private var isLoading = false
    @State private var errorMessage: AlertMessage?
    
    // State for navigating to lesson
    @State private var selectedLesson: Lesson?
    @State private var showLessonView = false
    
    // Track daily goal progress
    private var dailyGoalProgress: Float {
        return min(Float(userViewModel.completedLessons.count) / Float(userViewModel.learningGoal), 1.0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Top section - User info & daily goal
                    userHeader
                    
                    // AI recommended lesson section
                    recommendedLessonSection
                    
                    // Lesson categories grid
                    lessonCategoriesSection
                    
                    // Progress & analytics section
                    progressSection
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Dashboard")
            .background(Color("BackgroundLight"))
            .onAppear(perform: loadLearningProgress)
            .sheet(isPresented: $showLessonView) {
                if let lesson = selectedLesson {
                    let viewModel = LessonViewModel(lesson: lesson)
                    LessonView(lesson: lesson, userViewModel: userViewModel, lessonViewModel: viewModel)
                }
            }
            .alert(item: $errorMessage) { message in
                Alert(
                    title: Text(message.title),
                    message: Text(message.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Component Views
    
    /// User profile header with avatar and daily goal progress
    private var userHeader: some View {
        HStack(spacing: 12) {
            // User avatar
            Image(userViewModel.avatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                // Greeting with user name
                Text("Hello, \(userViewModel.name)!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("DarkGray"))
                
                // Daily goal progress
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Goal: \(userViewModel.completedLessons.count)/\(userViewModel.learningGoal) lessons")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("DarkGray"))
                    
                    ProgressView(value: dailyGoalProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                        .frame(height: 8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// AI-recommended lessons section
    private var recommendedLessonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended For You")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let progress = learningProgress, !progress.recommendedLessons.isEmpty {
                // Create a lesson from the first recommended lesson ID
                let _ = progress.recommendedLessons.first!
                let recommendedLesson = Lesson(
                    userId: userViewModel.id,
                    subject: .arithmetic // Default subject, would be from the actual lesson in a real app
                )
                
                // Display the recommended lesson card
                RecommendedLessonCard(lesson: recommendedLesson) {
                    // Start the recommended lesson
                    selectedLesson = recommendedLesson
                    showLessonView = true
                }
            } else {
                // Fallback when no recommendations
                Text("No recommendations available yet. Complete a lesson to get personalized suggestions.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Lesson categories grid section
    private var lessonCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lesson Categories")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                // Logic & Arithmetic
                CategoryCard(
                    title: "Logical Thinking",
                    systemImage: "brain",
                    color: .blue
                ) {
                    navigateToLessonList(subject: .logicalThinking)
                }
                
                CategoryCard(
                    title: "Arithmetic",
                    systemImage: "plus.forwardslash.minus",
                    color: .green
                ) {
                    navigateToLessonList(subject: .arithmetic)
                }
                
                // Number Theory & Geometry
                CategoryCard(
                    title: "Number Theory",
                    systemImage: "number",
                    color: .purple
                ) {
                    navigateToLessonList(subject: .numberTheory)
                }
                
                CategoryCard(
                    title: "Geometry",
                    systemImage: "triangle",
                    color: .orange
                ) {
                    navigateToLessonList(subject: .geometry)
                }
                
                // Combinatorics
                CategoryCard(
                    title: "Combinatorics",
                    systemImage: "square.grid.2x2",
                    color: .red
                ) {
                    navigateToLessonList(subject: .combinatorics)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Progress and analytics section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            HStack(spacing: 16) {
                // Progress Report Button
                NavigationLink(destination: ProgressReportView(userViewModel: userViewModel)) {
                    ActionButton(
                        title: "Progress Report",
                        systemImage: "chart.bar",
                        color: .blue
                    )
                }
                
                // Review Mistakes Button
                NavigationLink(destination: ReviewMistakesView(userViewModel: userViewModel)) {
                    ActionButton(
                        title: "Review Mistakes",
                        systemImage: "arrow.clockwise",
                        color: Color("SecondaryYellow")
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    /// Load learning progress for the current user
    private func loadLearningProgress() {
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
    
    /// Navigate to a lesson list for a specific subject
    private func navigateToLessonList(subject: Lesson.Subject) {
        // Create a new lesson with the selected subject
        let newLesson = Lesson(userId: userViewModel.id, subject: subject)
        
        // Set as selected lesson and show lesson view
        selectedLesson = newLesson
        showLessonView = true
    }
}

// MARK: - Supporting Views

/// Card display for a recommended lesson
struct RecommendedLessonCard: View {
    let lesson: Lesson
    let action: () -> Void
    
    private let viewModel: LessonViewModel
    
    init(lesson: Lesson, action: @escaping () -> Void) {
        self.lesson = lesson
        self.action = action
        self.viewModel = LessonViewModel(lesson: lesson)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Subject icon
                    Image(systemName: viewModel.subjectIconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(viewModel.subjectColor)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.subjectDisplayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("DarkGray"))
                        
                        Text("Difficulty: \(viewModel.difficultyName)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                Text("Start Today's Practice")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Category card for lesson subjects
struct CategoryCard: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("DarkGray"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Action button for progress section
struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("DarkGray"))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            name: "Test Student",
            avatar: "avatar-1",
            gradeLevel: 5
        )
        let userViewModel = UserViewModel(user: user)
        
        return DashboardView(userViewModel: userViewModel)
    }
} 