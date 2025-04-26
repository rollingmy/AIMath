import SwiftUI

/// Main home dashboard view serving as the central hub for the app
struct HomeView: View {
    @ObservedObject var userViewModel: UserViewModel
    @State private var selectedSubject: Lesson.Subject?
    @State private var showingLessonView = false
    @State private var showingPerformanceView = false
    @State private var showingSettingsView = false
    @State private var showingReviewMistakes = false
    
    // Mock recommended lesson for UI development 
    @State private var recommendedLesson: Lesson
    
    // For backward compatibility with simple preview methods
    init(user: User) {
        self.userViewModel = UserViewModel(user: user)
        
        // Initialize a recommended lesson with questions
        var lesson = Lesson(
            id: UUID(),
            userId: user.id,
            subject: .arithmetic,
            difficulty: 2,
            questions: [],
            responses: [],
            accuracy: 0.0,
            responseTime: 0.0,
            startedAt: Date(),
            completedAt: nil,
            status: .notStarted
        )
        
        // Use string IDs that match the format in timo_questions.json
        let timoQuestionIDs = [
            "arithmetic-1", "arithmetic-2", "arithmetic-3", "arithmetic-4", "arithmetic-5",
            "logical-1", "logical-2", "logical-3", "logical-4", "logical-5"
        ]
        
        // Convert string IDs to UUIDs and add to lesson
        for id in timoQuestionIDs {
            lesson.questions.append(UUID(uuidString: id) ?? UUID())
        }
        
        self._recommendedLesson = State(initialValue: lesson)
    }
    
    // For use with the ViewModel
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        
        // Initialize a recommended lesson with questions
        var lesson = Lesson(
            id: UUID(),
            userId: userViewModel.user.id,
            subject: .arithmetic,
            difficulty: 2,
            questions: [],
            responses: [],
            accuracy: 0.0,
            responseTime: 0.0,
            startedAt: Date(),
            completedAt: nil,
            status: .notStarted
        )
        
        // Use string IDs that match the format in timo_questions.json
        let timoQuestionIDs = [
            "arithmetic-1", "arithmetic-2", "arithmetic-3", "arithmetic-4", "arithmetic-5",
            "logical-1", "logical-2", "logical-3", "logical-4", "logical-5"
        ]
        
        // Convert string IDs to UUIDs and add to lesson
        for id in timoQuestionIDs {
            lesson.questions.append(UUID(uuidString: id) ?? UUID())
        }
        
        self._recommendedLesson = State(initialValue: lesson)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top section with user greeting and progress
                    userHeaderSection
                    
                    // Today's recommended lesson
                    recommendedLessonSection
                    
                    // Subject selection grid
                    subjectSelectionSection
                    
                    // Progress overview
                    progressOverviewSection
                    
                    // Bottom actions
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("TIMO Math")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettingsView = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingLessonView) {
                NavigationView {
                    if let subject = selectedSubject {
                        // Create a lesson for the specific subject
                        let lesson = createLessonForSubject(subject)
                        LessonView(lesson: lesson, userViewModel: userViewModel, subjectFilter: subject)
                    } else {
                        // Use the recommended lesson if no subject is selected
                        LessonView(lesson: recommendedLesson, userViewModel: userViewModel)
                    }
                }
            }
            .sheet(isPresented: $showingPerformanceView) {
                PerformanceView(userViewModel: userViewModel)
            }
            .sheet(isPresented: $showingSettingsView) {
                SettingsView(userViewModel: userViewModel)
            }
            .sheet(isPresented: $showingReviewMistakes) {
                NavigationView {
                    ReviewMistakesView(userViewModel: userViewModel)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    // User header with avatar, greeting and daily progress
    private var userHeaderSection: some View {
        HStack(spacing: 15) {
            // User avatar
            AvatarImageView(avatarName: userViewModel.user.avatar, size: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                // Greeting with user name
                Text("Hello, \(userViewModel.user.name)!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Daily progress
                Text("Daily Goal: \(userViewModel.user.completedLessons.count)/\(userViewModel.user.learningGoal) questions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Daily goal progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(Double(userViewModel.user.completedLessons.count) / Double(userViewModel.user.learningGoal), 1.0)))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(min(Double(userViewModel.user.completedLessons.count) / Double(userViewModel.user.learningGoal) * 100, 100)))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // AI recommended lesson card
    private var recommendedLessonSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recommended for You")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Recommended lesson card with title from displayTitle computed property
            Button(action: { showingLessonView = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(getLessonTitle())
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(subjectText(recommendedLesson.subject))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(difficultyText(recommendedLesson.difficulty))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyColor(recommendedLesson.difficulty).opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
            
            // Start today's practice button
            Button(action: { 
                selectedSubject = nil  // Ensure we use the recommended lesson
                showingLessonView = true 
            }) {
                Text("Start Today's Practice")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
        }
    }
    
    // Helper function to get a title for the lesson
    private func getLessonTitle() -> String {
        // In a real app, this would be part of the Lesson model
        return "Number Patterns"
    }
    
    // Subject selection grid
    private var subjectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Choose a Subject")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 15) {
                // Logical Thinking
                subjectButton(
                    title: "Logical Thinking",
                    iconName: "brain",
                    color: .purple,
                    subject: .logicalThinking
                )
                
                // Arithmetic
                subjectButton(
                    title: "Arithmetic",
                    iconName: "plus.forwardslash.minus",
                    color: .blue,
                    subject: .arithmetic
                )
                
                // Number Theory
                subjectButton(
                    title: "Number Theory",
                    iconName: "number.circle",
                    color: .green,
                    subject: .numberTheory
                )
                
                // Geometry
                subjectButton(
                    title: "Geometry",
                    iconName: "square.on.circle",
                    color: .orange,
                    subject: .geometry
                )
                
                // Combinatorics
                subjectButton(
                    title: "Combinatorics",
                    iconName: "chart.bar",
                    color: .red,
                    subject: .combinatorics
                )
            }
        }
    }
    
    // Helper method to create consistent subject buttons
    private func subjectButton(title: String, iconName: String, color: Color, subject: Lesson.Subject) -> some View {
        Button(action: {
            selectedSubject = subject
            showingLessonView = true
        }) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // Progress overview section with charts
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Progress Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            if userViewModel.user.completedLessons.isEmpty {
                // When no lessons are completed, show a placeholder message
                VStack(spacing: 15) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Complete lessons to see your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
            } else {
                // When there's data, show the bar chart using completed lessons
                HStack(alignment: .bottom, spacing: 12) {
                    // Get data from completedLessons array
                    let completedLessons = getCompletedLessonsBySubject()
                    let totalLessons = Float(userViewModel.user.completedLessons.count)
                    
                    // Logical Thinking bar
                    let logicCount = Float(completedLessons[.logicalThinking]?.count ?? 0)
                    let logicHeight = totalLessons > 0 ? min(logicCount / totalLessons, 1.0) : 0.0
                    VStack {
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: 30, height: 80 * CGFloat(logicHeight))
                        
                        Text("Logic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Arithmetic bar
                    let arithmeticCount = Float(completedLessons[.arithmetic]?.count ?? 0)
                    let arithmeticHeight = totalLessons > 0 ? min(arithmeticCount / totalLessons, 1.0) : 0.0
                    VStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 80 * CGFloat(arithmeticHeight))
                        
                        Text("Arith")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Number Theory bar
                    let numberCount = Float(completedLessons[.numberTheory]?.count ?? 0)
                    let numberHeight = totalLessons > 0 ? min(numberCount / totalLessons, 1.0) : 0.0
                    VStack {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 30, height: 80 * CGFloat(numberHeight))
                        
                        Text("Num")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Geometry bar
                    let geoCount = Float(completedLessons[.geometry]?.count ?? 0)
                    let geoHeight = totalLessons > 0 ? min(geoCount / totalLessons, 1.0) : 0.0
                    VStack {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 30, height: 80 * CGFloat(geoHeight))
                        
                        Text("Geo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Combinatorics bar
                    let combCount = Float(completedLessons[.combinatorics]?.count ?? 0)
                    let combHeight = totalLessons > 0 ? min(combCount / totalLessons, 1.0) : 0.0
                    VStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 30, height: 80 * CGFloat(combHeight))
                        
                        Text("Comb")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    VStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            Divider()
                                .offset(y: 16 * CGFloat(i))
                        }
                    }
                    .padding(.bottom, 20)
                )
            }
            
            // Overall accuracy
            HStack {
                Text("Overall Accuracy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if userViewModel.user.completedLessons.isEmpty {
                    Text("0%")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    // Calculate actual accuracy from lesson data
                    let accuracy = calculateOverallAccuracy()
                    let percentage = Int(accuracy * 100)
                    Text("\(percentage)%")
                        .font(.headline)
                        .foregroundColor(percentage > 60 ? .green : .orange)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // Action buttons at the bottom
    private var actionButtonsSection: some View {
        HStack(spacing: 15) {
            // View detailed performance
            Button(action: { showingPerformanceView = true }) {
                VStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 24))
                    
                    // Show stats if available
                    if !userViewModel.user.completedLessons.isEmpty {
                        let accuracy = Int(calculateOverallAccuracy() * 100)
                        Text("Performance \(accuracy)%")
                            .font(.caption)
                    } else {
                        Text("Performance")
                            .font(.caption)
                    }
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
            
            // Review mistakes
            Button(action: { showingReviewMistakes = true }) {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                    
                    // Show count of incorrect answers if any
                    if let mistakeCount = countIncorrectAnswers(), mistakeCount > 0 {
                        Text("Review Mistakes (\(mistakeCount))")
                            .font(.caption)
                    } else {
                        Text("Review Mistakes")
                            .font(.caption)
                    }
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func subjectText(_ subject: Lesson.Subject) -> String {
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
    
    private func difficultyText(_ difficulty: Int) -> String {
        switch difficulty {
        case 1:
            return "Easy"
        case 2:
            return "Medium"
        case 3:
            return "Hard"
        case 4:
            return "Olympiad"
        default:
            return "Unknown"
        }
    }
    
    private func difficultyColor(_ difficulty: Int) -> Color {
        switch difficulty {
        case 1:
            return .green
        case 2:
            return .blue
        case 3:
            return .orange
        case 4:
            return .red
        default:
            return .gray
        }
    }
    
    /// Creates a lesson for the selected subject with predefined questions
    private func createLessonForSubject(_ subject: Lesson.Subject) -> Lesson {
        // Create a new lesson with the given subject
        var lesson = Lesson(
            userId: userViewModel.user.id,
            subject: subject
        )
        
        // Set appropriate difficulty level
        lesson.difficulty = 2 // Medium difficulty
        
        // Use string IDs that match the format in timo_questions.json
        var timoQuestionIDs: [String] = []
        
        // Select appropriate question IDs based on the subject
        switch subject {
        case .arithmetic:
            timoQuestionIDs = ["arithmetic-1", "arithmetic-2", "arithmetic-3", "arithmetic-4", "arithmetic-5"]
        case .logicalThinking:
            timoQuestionIDs = ["logical-1", "logical-2", "logical-3", "logical-4", "logical-5"]
        case .geometry:
            // For subjects without specific questions, we'll use a mix
            timoQuestionIDs = ["geometry-1", "geometry-2", "arithmetic-3", "logical-3", "arithmetic-5"]
        case .numberTheory:
            timoQuestionIDs = ["number-theory-1", "number-theory-2", "arithmetic-4", "logical-4", "arithmetic-2"]
        case .combinatorics:
            timoQuestionIDs = ["combinatorics-1", "combinatorics-2", "arithmetic-1", "logical-5", "arithmetic-3"]
        }
        
        // Convert string IDs to UUIDs and add to lesson
        for id in timoQuestionIDs {
            lesson.questions.append(UUID(uuidString: id) ?? UUID())
        }
        
        return lesson
    }
    
    // Helper method to get completed lessons by subject
    private func getCompletedLessonsBySubject() -> [Lesson.Subject: [UUID]] {
        let subjects: [Lesson.Subject] = [.arithmetic, .geometry, .numberTheory, .logicalThinking, .combinatorics]
        var result = [Lesson.Subject: [UUID]]()
        
        // Initialize with empty arrays
        for subject in subjects {
            result[subject] = []
        }
        
        // Get mock lessons from completed lesson IDs
        let mockLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        // Group by subject
        for lesson in mockLessons {
            var subjectLessons = result[lesson.subject] ?? []
            subjectLessons.append(lesson.id)
            result[lesson.subject] = subjectLessons
        }
        
        return result
    }
    
    // Calculate overall accuracy from completed lessons
    private func calculateOverallAccuracy() -> Float {
        let mockLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        if mockLessons.isEmpty {
            return 0.0
        }
        
        let totalAccuracy = mockLessons.reduce(0.0) { $0 + Float($1.accuracy) }
        return totalAccuracy / Float(mockLessons.count)
    }
    
    // Count total incorrect answers for display
    private func countIncorrectAnswers() -> Int? {
        let mockLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        if mockLessons.isEmpty {
            return nil
        }
        
        var totalIncorrect = 0
        for lesson in mockLessons {
            for response in lesson.responses {
                if !response.isCorrect {
                    totalIncorrect += 1
                }
            }
        }
        
        return totalIncorrect > 0 ? totalIncorrect : nil
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
                    answeredAt: Date()
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
                completedAt: Date(),
                status: .completed
            )
            
            mockLessons.append(lesson)
        }
        
        return mockLessons
    }
    
    // Called when a lesson is completed to update user progress
    func lessonCompleted(_ lesson: Lesson) {
        // Update user's completed lessons
        userViewModel.addCompletedLesson(lesson.id)
        
        // Track user activity
        userViewModel.trackActivity()
        
        // If adaptive difficulty is enabled, update difficulty level based on performance
        if userViewModel.user.difficultyLevel == .adaptive {
            // Check performance to potentially adjust difficulty
            if lesson.accuracy >= 0.8 {
                // User is doing well, consider increasing difficulty
                if shouldIncreaseDifficulty() {
                    userViewModel.updateDifficultyLevel(.advanced)
                }
            } else if lesson.accuracy <= 0.4 {
                // User is struggling, consider decreasing difficulty
                userViewModel.updateDifficultyLevel(.beginner)
            }
        }
    }
    
    // Determine if difficulty should increase based on recent performance
    private func shouldIncreaseDifficulty() -> Bool {
        let recentLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
            .sorted(by: { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) })
            .prefix(3)
        
        // Only increase difficulty if user has completed at least 3 lessons
        guard recentLessons.count >= 3 else {
            return false
        }
        
        // Check if user has consistently high accuracy in recent lessons
        let highAccuracyCount = recentLessons.filter { $0.accuracy >= 0.8 }.count
        return highAccuracyCount >= 2 // At least 2 out of 3 recent lessons had high accuracy
    }
}

#Preview {
    let user = User(
        name: "Alex",
        avatar: "avatar-1",
        gradeLevel: 3
    )
    return HomeView(user: user)
} 