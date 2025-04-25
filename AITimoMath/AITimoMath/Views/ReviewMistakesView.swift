import SwiftUI

/// View for reviewing past incorrect answers
struct ReviewMistakesView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var mistakes: [MistakeItem] = []
    @State private var isLoading = true
    @State private var selectedSubject: Lesson.Subject?
    @State private var error: Error?
    @State private var currentMistakeIndex = 0
    @State private var selectedOptionIndex: Int?
    @State private var isShowingAnswer = false
    
    // Mock data for UI development
    struct MistakeItem: Identifiable {
        let id = UUID()
        let question: Question
        let userAnswer: Int? // The user's incorrect answer index
        let date: Date
        let lessonId: UUID
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
        VStack {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if mistakes.isEmpty {
                noMistakesView
            } else {
                mistakesReviewView
            }
        }
        .navigationTitle("Review Mistakes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !mistakes.isEmpty {
                    Menu {
                        // Filter by subject
                        Menu("Filter by Subject") {
                            Button("All Subjects") {
                                selectedSubject = nil
                            }
                            
                            Divider()
                            
                            Button("Logical Thinking") {
                                selectedSubject = .logicalThinking
                            }
                            
                            Button("Arithmetic") {
                                selectedSubject = .arithmetic
                            }
                            
                            Button("Number Theory") {
                                selectedSubject = .numberTheory
                            }
                            
                            Button("Geometry") {
                                selectedSubject = .geometry
                            }
                            
                            Button("Combinatorics") {
                                selectedSubject = .combinatorics
                            }
                        }
                        
                        // Sort options
                        Menu("Sort") {
                            Button("Newest First") {
                                sortMistakes(by: .date, ascending: false)
                            }
                            
                            Button("Oldest First") {
                                sortMistakes(by: .date, ascending: true)
                            }
                            
                            Button("By Difficulty (Hardest First)") {
                                sortMistakes(by: .difficulty, ascending: false)
                            }
                            
                            Button("By Difficulty (Easiest First)") {
                                sortMistakes(by: .difficulty, ascending: true)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .onAppear {
            loadMistakes()
        }
    }
    
    // MARK: - Sub Views
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading your review items...")
                .font(.headline)
        }
    }
    
    // Error view
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error loading review items")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadMistakes()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // No mistakes view
    private var noMistakesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("No Mistakes to Review")
                .font(.title2)
                .fontWeight(.bold)
            
            if selectedSubject != nil {
                Text("You don't have any mistakes in this subject. Try selecting a different subject or keep practicing!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Great job! You haven't made any mistakes that need reviewing yet. Keep practicing to improve your skills!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button("Back to Dashboard") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding()
    }
    
    // Main review content
    private var mistakesReviewView: some View {
        VStack(spacing: 0) {
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(currentMistakeIndex + 1) / CGFloat(filteredMistakes.count) * UIScreen.main.bounds.width, height: 8)
            }
            
            // Main content
            VStack(spacing: 20) {
                // Question counter and date
                HStack {
                    Text("Question \(currentMistakeIndex + 1) of \(filteredMistakes.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(filteredMistakes[currentMistakeIndex].date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Subject and difficulty badges
                        HStack {
                            Text(formatSubject(currentMistake.question.subject))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(subjectColor(currentMistake.question.subject).opacity(0.2))
                                .cornerRadius(8)
                            
                            Text(formatDifficulty(currentMistake.question.difficulty))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(difficultyColor(currentMistake.question.difficulty).opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        // Question text
                        Text(currentMistake.question.questionText)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Question image if any
                        if let image = currentMistake.question.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        
                        // Answer options
                        if let options = currentMistake.question.options {
                            VStack(spacing: 12) {
                                ForEach(0..<options.count, id: \.self) { index in
                                    HStack(alignment: .top) {
                                        // Option letter (A, B, C, etc.)
                                        Text("\(Character(UnicodeScalar(65 + index)!))")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 30, height: 30)
                                            .background(
                                                Circle()
                                                    .fill(optionColor(index))
                                            )
                                        
                                        // Option content
                                        if let text = options[index].textValue {
                                            Text(text)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        // Indicators for user's wrong answer and correct answer
                                        if isShowingAnswer {
                                            if isCorrectOption(index) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            } else if index == currentMistake.userAnswer {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(optionBackground(index))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Explanation (when showing answer)
                        if isShowingAnswer, let hint = currentMistake.question.hint {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Explanation")
                                    .font(.headline)
                                
                                Text(hint)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical)
                }
                
                // Action buttons
                VStack(spacing: 15) {
                    if isShowingAnswer {
                        // Next question button
                        Button(action: nextMistake) {
                            Text(currentMistakeIndex < filteredMistakes.count - 1 ? "Next Question" : "Finish Review")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                    } else {
                        // Show answer button
                        Button(action: {
                            withAnimation {
                                isShowingAnswer = true
                            }
                        }) {
                            Text("Show Solution")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Navigation buttons
                    HStack {
                        // Previous button
                        Button(action: previousMistake) {
                            Label("Previous", systemImage: "arrow.left")
                                .font(.subheadline)
                        }
                        .disabled(currentMistakeIndex == 0)
                        
                        Spacer()
                        
                        // Navigation label
                        Text("\(currentMistakeIndex + 1) / \(filteredMistakes.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Next button
                        Button(action: {
                            if isShowingAnswer {
                                nextMistake()
                            } else {
                                // Skip directly to next without showing answer
                                currentMistakeIndex = min(currentMistakeIndex + 1, filteredMistakes.count - 1)
                            }
                        }) {
                            Label("Next", systemImage: "arrow.right")
                                .font(.subheadline)
                        }
                        .disabled(currentMistakeIndex >= filteredMistakes.count - 1)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 15)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Current mistake being displayed
    private var currentMistake: MistakeItem {
        filteredMistakes[currentMistakeIndex]
    }
    
    // Filtered mistakes based on subject selection
    private var filteredMistakes: [MistakeItem] {
        if let subject = selectedSubject {
            return mistakes.filter { $0.question.subject == subject }
        } else {
            return mistakes
        }
    }
    
    // Load user's past mistakes
    private func loadMistakes() {
        isLoading = true
        error = nil
        
        // In a real app, we would fetch from a data store
        // For now, we'll create mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Create sample mistake data
            var mockMistakes: [MistakeItem] = []
            
            // Add some sample mistakes - in real app these would come from user's history
            
            // Arithmetic mistake
            var q1 = Question(
                subject: .arithmetic,
                difficulty: 2,
                type: .multipleChoice,
                questionText: "What is the result of 125 ÷ 5?",
                correctAnswer: "25"
            )
            q1.options = [
                .text("20"),
                .text("25"),
                .text("30"),
                .text("35")
            ]
            q1.hint = "To divide 125 by 5, we can think of it as (100 + 25) ÷ 5 = 100 ÷ 5 + 25 ÷ 5 = 20 + 5 = 25."
            mockMistakes.append(MistakeItem(
                question: q1,
                userAnswer: 0, // User selected "20" incorrectly
                date: Date().addingTimeInterval(-86400), // Yesterday
                lessonId: UUID()
            ))
            
            // Geometry mistake
            var q2 = Question(
                subject: .geometry,
                difficulty: 3,
                type: .multipleChoice,
                questionText: "What is the area of a square with a side length of 8 cm?",
                correctAnswer: "64 cm²"
            )
            q2.options = [
                .text("16 cm²"),
                .text("32 cm²"),
                .text("64 cm²"),
                .text("128 cm²")
            ]
            q2.hint = "The area of a square is calculated as side length × side length. So, 8 cm × 8 cm = 64 cm²."
            mockMistakes.append(MistakeItem(
                question: q2,
                userAnswer: 1, // User selected "32 cm²" incorrectly
                date: Date().addingTimeInterval(-172800), // 2 days ago
                lessonId: UUID()
            ))
            
            // Number Theory mistake
            var q3 = Question(
                subject: .numberTheory,
                difficulty: 3,
                type: .multipleChoice,
                questionText: "What is the greatest common divisor (GCD) of 24 and 36?",
                correctAnswer: "12"
            )
            q3.options = [
                .text("6"),
                .text("8"),
                .text("12"),
                .text("18")
            ]
            q3.hint = "To find the GCD, list all factors of both numbers: Factors of 24: 1, 2, 3, 4, 6, 8, 12, 24. Factors of 36: 1, 2, 3, 4, 6, 9, 12, 18, 36. The largest common factor is 12."
            mockMistakes.append(MistakeItem(
                question: q3,
                userAnswer: 0, // User selected "6" incorrectly
                date: Date().addingTimeInterval(-259200), // 3 days ago
                lessonId: UUID()
            ))
            
            // Logical Thinking mistake
            var q4 = Question(
                subject: .logicalThinking,
                difficulty: 2,
                type: .multipleChoice,
                questionText: "If all cats have tails, and Fluffy has a tail, which of the following must be true?",
                correctAnswer: "Fluffy might be a cat"
            )
            q4.options = [
                .text("Fluffy is a cat"),
                .text("Fluffy might be a cat"),
                .text("Fluffy is not a cat"),
                .text("All animals with tails are cats")
            ]
            q4.hint = "This is a logical reasoning question. Having a tail is a necessary but not sufficient condition for being a cat. Many animals have tails, so Fluffy might be a cat, but could also be another animal with a tail."
            mockMistakes.append(MistakeItem(
                question: q4,
                userAnswer: 0, // User selected "Fluffy is a cat" incorrectly
                date: Date().addingTimeInterval(-345600), // 4 days ago
                lessonId: UUID()
            ))
            
            // Reset state and update UI
            DispatchQueue.main.async {
                self.mistakes = mockMistakes
                self.currentMistakeIndex = 0
                self.isShowingAnswer = false
                self.isLoading = false
            }
        }
    }
    
    // Move to next mistake
    private func nextMistake() {
        if currentMistakeIndex < filteredMistakes.count - 1 {
            currentMistakeIndex += 1
            isShowingAnswer = false
        } else {
            // Completed all mistakes
            dismiss()
        }
    }
    
    // Move to previous mistake
    private func previousMistake() {
        if currentMistakeIndex > 0 {
            currentMistakeIndex -= 1
            isShowingAnswer = false
        }
    }
    
    // Sort mistakes
    private func sortMistakes(by criterion: SortCriterion, ascending: Bool) {
        switch criterion {
        case .date:
            mistakes.sort { item1, item2 in
                ascending ? item1.date < item2.date : item1.date > item2.date
            }
        case .difficulty:
            mistakes.sort { item1, item2 in
                ascending ? 
                    item1.question.difficulty < item2.question.difficulty : 
                    item1.question.difficulty > item2.question.difficulty
            }
        }
        
        // Reset to first item
        currentMistakeIndex = 0
        isShowingAnswer = false
    }
    
    // Sort criteria
    private enum SortCriterion {
        case date
        case difficulty
    }
    
    // Format a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Check if an option is the correct one
    private func isCorrectOption(_ index: Int) -> Bool {
        guard let options = currentMistake.question.options,
              index < options.count else { return false }
        
        if let optionText = options[index].textValue,
           optionText == currentMistake.question.correctAnswer {
            return true
        }
        
        return false
    }
    
    // Get option circle color
    private func optionColor(_ index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return .green
            } else if index == currentMistake.userAnswer {
                return .red
            }
        }
        
        return .gray
    }
    
    // Get option background color
    private func optionBackground(_ index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return Color.green.opacity(0.1)
            } else if index == currentMistake.userAnswer {
                return Color.red.opacity(0.1)
            }
        }
        
        return Color(.systemGray6)
    }
    
    // Format subject for display
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
    
    // Format difficulty for display
    private func formatDifficulty(_ difficulty: Int) -> String {
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
    
    // Get subject color
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
    
    // Get difficulty color
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
}

#Preview {
    let user = User(
        name: "Alex",
        avatar: "avatar-1",
        gradeLevel: 3
    )
    ReviewMistakesView(user: user)
} 