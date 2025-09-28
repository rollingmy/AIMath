import SwiftUI

struct SubjectLessonsView: View {
    let subject: String
    let iconName: String
    @ObservedObject var user: User
    
    @State private var lessons: [Lesson] = []
    @State private var isLoading = true
    
    // Get difficulty levels based on user's difficulty preference
    private var difficulties: [Int] {
        return user.difficultyLevel.difficultyRange
    }
    
    // Function to load lessons for the selected subject
    private func loadLessons() {
        isLoading = true
        
        Task {
            do {
                // Load real questions from QuestionService
                let questionService = QuestionService.shared
                let allQuestions = try await questionService.loadQuestions()
                
                // Filter questions by subject
                let subjectEnum = getSubjectEnum(from: subject)
                let subjectQuestions = allQuestions.filter { $0.subject == subjectEnum }
                
                // Group questions by difficulty to create lessons
                let questionsByDifficulty = Dictionary(grouping: subjectQuestions) { $0.difficulty }
                
                var newLessons: [Lesson] = []
                
                // Create lessons for each difficulty level
                print("🔍 User difficulty level: \(user.difficultyLevel.displayName)")
                print("🔍 Requested difficulties: \(difficulties)")
                print("🔍 Available difficulties for \(subject): \(Set(subjectQuestions.map { $0.difficulty }).sorted())")
                
                for difficulty in difficulties.sorted() {
                    if var qs = questionsByDifficulty[difficulty], !qs.isEmpty {
                        print("✅ Found \(qs.count) questions for difficulty \(difficulty)")
                        // Top up to daily goal using same-subject nearest difficulties
                        let target = user.dailyGoal
                        if qs.count < target {
                            let order = [difficulty, max(1, difficulty-1), min(4, difficulty+1), max(1, difficulty-2), min(4, difficulty+2)]
                            for d in order where d != difficulty {
                                guard qs.count < target else { break }
                                if let extra = questionsByDifficulty[d] {
                                    for q in extra where !qs.contains(q) {
                                        guard qs.count < target else { break }
                                        qs.append(q)
                                    }
                                }
                            }
                        }
                        var lesson = Lesson(
                            userId: user.id,
                            subject: subjectEnum
                        )
                        lesson.difficulty = difficulty
                        lesson.questions = Array(qs.prefix(target)).map { $0.id }
                        newLessons.append(lesson)
                    }
                }
                
                // If no questions found for the selected difficulty range, 
                // try to find questions in the fallback difficulty range
                if newLessons.isEmpty {
                    print("⚠️ No lessons created for preferred difficulties, using fallback")
                    // Use fallback difficulty range (all difficulties)
                    let fallbackDifficulties = [1, 2, 3, 4]
                    print("🔍 Fallback difficulties: \(fallbackDifficulties)")
                    
                    for difficulty in fallbackDifficulties.sorted() {
                        if var qs = questionsByDifficulty[difficulty], !qs.isEmpty {
                            print("✅ Fallback: Found \(qs.count) questions for difficulty \(difficulty)")
                            // Top up to daily goal using same-subject nearest difficulties
                            let target = user.dailyGoal
                            if qs.count < target {
                                let order = [difficulty, max(1, difficulty-1), min(4, difficulty+1), max(1, difficulty-2), min(4, difficulty+2)]
                                for d in order where d != difficulty {
                                    guard qs.count < target else { break }
                                    if let extra = questionsByDifficulty[d] {
                                        for q in extra where !qs.contains(q) {
                                            guard qs.count < target else { break }
                                            qs.append(q)
                                        }
                                    }
                                }
                            }
                            var lesson = Lesson(
                                userId: user.id,
                                subject: subjectEnum
                            )
                            lesson.difficulty = difficulty
                            lesson.questions = Array(qs.prefix(target)).map { $0.id }
                            newLessons.append(lesson)
                        }
                    }
                    
                    // If still no questions found, create a default lesson
                    if newLessons.isEmpty {
                        var defaultLesson = Lesson(
                            userId: user.id,
                            subject: subjectEnum
                        )
                        defaultLesson.difficulty = 1
                        newLessons.append(defaultLesson)
                    }
                }
                
                await MainActor.run {
                    self.lessons = newLessons
                    self.isLoading = false
                    print("🎯 Final result: Created \(newLessons.count) lessons for \(subject)")
                    for lesson in newLessons {
                        print("   - Difficulty \(lesson.difficulty): \(lesson.questions.count) questions")
                    }
                }
            } catch {
                print("Error loading lessons for \(subject): \(error)")
                await MainActor.run {
                    // Fallback to a single default lesson
                    var defaultLesson = Lesson(
                        userId: user.id,
                        subject: getSubjectEnum(from: subject)
                    )
                    defaultLesson.difficulty = 1
                    self.lessons = [defaultLesson]
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
        VStack {
            subjectHeader
            
            if isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else {
                lessonsList
            }
        }
        .navigationTitle(subject)
        .onAppear {
            loadLessons()
        }
    }
    
    // MARK: - Computed Properties
    private var subjectHeader: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 25))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(subject)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
    }
    
    private var lessonsList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(lessons) { lesson in
                    NavigationLink(destination: LessonDetailView(lesson: lesson, user: user)) {
                        lessonCard(for: lesson)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func lessonCard(for lesson: Lesson) -> some View {
        HStack {
            // Status indicator
            Circle()
                .fill(lesson.status == .completed ? Color.green : Color.orange)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(getSubjectString(from: lesson.subject))
                    .font(.headline)
                
                Text(getLessonDescription(for: lesson))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(getDifficultyText(lesson.difficulty))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getDifficultyColor(lesson.difficulty).opacity(0.1))
                        .foregroundColor(getDifficultyColor(lesson.difficulty))
                        .cornerRadius(4)
                    
                    if !lesson.questions.isEmpty {
                        Text("\(lesson.questions.count) questions")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if lesson.status == .completed {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Start Lesson")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Helper function to convert Subject enum to string
    private func getSubjectString(from subject: Lesson.Subject) -> String {
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
    
    // Helper to get color based on difficulty
    private func getDifficultyColor(_ difficulty: Int) -> Color {
        switch difficulty {
        case 1:
            return .green
        case 2:
            return .blue
        case 3:
            return .orange
        case 4:
            return .purple
        default:
            return .blue
        }
    }
    
    // Helper to get difficulty text
    private func getDifficultyText(_ difficulty: Int) -> String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        case 4: return "Olympiad"
        default: return "Medium"
        }
    }
    
    // Helper to get lesson description
    private func getLessonDescription(for lesson: Lesson) -> String {
        let subjectName = getSubjectString(from: lesson.subject).lowercased()
        let difficultyText = getDifficultyText(lesson.difficulty).lowercased()
        return "Practice \(difficultyText) level \(subjectName) problems"
    }
}

// MARK: - Preview
struct SubjectLessonsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubjectLessonsView(
                subject: "Logical Thinking",
                iconName: "brain",
                user: User(
                    name: "Alex",
                    avatar: "avatar-1",
                    gradeLevel: 5
                )
            )
        }
    }
} 