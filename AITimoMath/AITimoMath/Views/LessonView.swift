import SwiftUI

/// View for displaying a lesson with multiple questions
struct LessonView: View {
    // Lesson data
    let lesson: Lesson
    @ObservedObject var userViewModel: UserViewModel
    
    // Optional subject filter
    let subjectFilter: Lesson.Subject?
    
    // State
    @State private var currentQuestionIndex = 0
    @State private var selectedOptionIndex: Int?
    @State private var userAnswers: [Int?] = []
    @State private var startTime: Date = Date()
    @State private var questionTimes: [TimeInterval] = []
    @State private var isShowingAnswer = false
    @State private var isLessonComplete = false
    @State private var questions: [Question] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    
    // Services
    private let questionService = QuestionService.shared
    
    // For backward compatibility with existing code
    init(lesson: Lesson, user: User, subjectFilter: Lesson.Subject? = nil) {
        self.lesson = lesson
        self.userViewModel = UserViewModel(user: user)
        self.subjectFilter = subjectFilter
        
        // Initialize userAnswers array with nil values
        self._userAnswers = State(initialValue: Array(repeating: nil, count: 10)) // Default to 10 questions
    }
    
    // Primary initializer using UserViewModel
    init(lesson: Lesson, userViewModel: UserViewModel, subjectFilter: Lesson.Subject? = nil) {
        self.lesson = lesson
        self.userViewModel = userViewModel
        self.subjectFilter = subjectFilter
        
        // Initialize userAnswers array with nil values
        self._userAnswers = State(initialValue: Array(repeating: nil, count: 10)) // Default to 10 questions
    }
    
    var body: some View {
        VStack {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if isLessonComplete {
                lessonSummaryView
            } else if !questions.isEmpty {
                lessonContentView
            } else {
                noQuestionsView
            }
        }
        .navigationTitle(getLessonTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Exit") {
                    // Show confirmation if lesson not complete
                    if !isLessonComplete && !userAnswers.allSatisfy({ $0 != nil }) {
                        // Would show confirmation dialog
                        dismiss()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadQuestions()
        }
    }
    
    // Get a formatted title for the lesson
    private func getLessonTitle() -> String {
        let subjectText = formatSubject(lesson.subject)
        let difficultyText = formatDifficulty(lesson.difficulty)
        return "\(subjectText) - \(difficultyText)"
    }
    
    // MARK: - Sub Views
    
    // Loading indicator
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading lesson content...")
                .font(.headline)
        }
    }
    
    // Error view
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error loading questions")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadQuestions()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // No questions view
    private var noQuestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No questions available for this lesson")
                .font(.headline)
            
            Button("Return to Dashboard") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // Main lesson content
    private var lessonContentView: some View {
        VStack(spacing: 0) {
            // Progress bar and question indicator
            progressHeader
            
            // Question content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question badges (subject, difficulty)
                    HStack {
                        // Subject badge
                        Text(formatSubject(questions[currentQuestionIndex].subject))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(subjectColor(questions[currentQuestionIndex].subject).opacity(0.2))
                            .cornerRadius(8)
                        
                        // Difficulty badge
                        Text(formatDifficulty(questions[currentQuestionIndex].difficulty))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyColor(questions[currentQuestionIndex].difficulty).opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Question text
                    Text(questions[currentQuestionIndex].questionText)
                        .font(.headline)
                        .lineSpacing(5)
                        .padding(.horizontal)
                    
                    // Question image if available
                    if let image = questions[currentQuestionIndex].image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Question options
                    if let options = questions[currentQuestionIndex].options, !options.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(0..<options.count, id: \.self) { index in
                                optionButton(option: options[index], index: index)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Hint button (if hint available and not showing answer)
                    if let hint = questions[currentQuestionIndex].hint, !hint.isEmpty, !isShowingAnswer {
                        Button {
                            // Show hint in alert or expand in UI
                        } label: {
                            Label("Show Hint", systemImage: "lightbulb")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                    }
                    
                    // Answer explanation (if showing answer)
                    if isShowingAnswer {
                        VStack(alignment: .leading, spacing: 15) {
                            // Correct answer indicator
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("Correct Answer: \(questions[currentQuestionIndex].correctAnswer)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            // Explanation
                            if let hint = questions[currentQuestionIndex].hint, !hint.isEmpty {
                                Text("Explanation:")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(hint)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
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
            
            // Action buttons at the bottom
            VStack(spacing: 10) {
                if isShowingAnswer {
                    // Next question button when answer is shown
                    Button(action: nextQuestion) {
                        Text(currentQuestionIndex < questions.count - 1 ? "Next Question" : "Finish Lesson")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                } else {
                    // Submit answer button
                    Button(action: submitAnswer) {
                        Text("Submit Answer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedOptionIndex != nil ? Color.blue : Color.gray)
                            .cornerRadius(15)
                    }
                    .disabled(selectedOptionIndex == nil)
                    .padding(.horizontal)
                }
                
                // Navigation buttons
                HStack {
                    // Previous button
                    Button(action: previousQuestion) {
                        Label("Previous", systemImage: "arrow.left")
                            .font(.subheadline)
                    }
                    .disabled(currentQuestionIndex == 0 || isShowingAnswer)
                    
                    Spacer()
                    
                    // Skip button (if not showing answer)
                    if !isShowingAnswer {
                        Button(action: {
                            // Skip to next without answering
                            recordAnswer(nil)
                            nextQuestion()
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .disabled(currentQuestionIndex >= questions.count - 1)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 15)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
    }
    
    // Progress indicator at the top
    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress text
            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Timer would go here in a real implementation
                // Text(formatElapsedTime())
                //     .font(.subheadline)
                //     .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: calculateProgressWidth(), height: 8)
                    .cornerRadius(4)
            }
            .padding(.horizontal)
            
            Divider()
        }
        .padding(.top, 10)
    }
    
    // Option button for multiple choice
    private func optionButton(option: Question.QuestionOption, index: Int) -> some View {
        Button(action: {
            if !isShowingAnswer {
                selectedOptionIndex = index
            }
        }) {
            HStack(alignment: .top) {
                // Option letter (A, B, C, etc.)
                Text("\(Character(UnicodeScalar(65 + index)!))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        optionBackgroundColor(index: index)
                    )
                    .clipShape(Circle())
                
                // Option content
                VStack(alignment: .leading, spacing: 10) {
                    if let text = option.textValue {
                        Text(text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let image = option.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 100)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Correct/incorrect indicator when showing answer
                if isShowingAnswer {
                    if isCorrectOption(index) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else if index == selectedOptionIndex {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(optionContentBackgroundColor(index: index))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(optionBorderColor(index: index), lineWidth: 2)
                    )
            )
        }
        .disabled(isShowingAnswer)
    }
    
    // Lesson summary view
    private var lessonSummaryView: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Completion header
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                    
                    Text("Lesson Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Great job completing the lesson")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                
                // Performance metrics
                HStack(spacing: 20) {
                    // Accuracy
                    VStack {
                        Text("\(calculateAccuracyPercentage())%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Average time
                    VStack {
                        Text(formatAverageTime())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("Avg. Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Incorrect answers summary
                if hasIncorrectAnswers() {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Areas to Review")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(incorrectQuestionIndices(), id: \.self) { index in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Question \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(questions[index].questionText)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("Correct Answer: ")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
                                    Text(questions[index].correctAnswer)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // Return to dashboard
                        dismiss()
                    }) {
                        Text("Continue to Dashboard")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    
                    if hasIncorrectAnswers() {
                        Button(action: {
                            // Would show incorrect questions again
                        }) {
                            Text("Retry Incorrect Questions")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                        }
                    }
                    
                    Button(action: {
                        // Would share progress report
                    }) {
                        Label("Share Results", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Helper Methods
    
    // Load questions for the lesson
    private func loadQuestions() {
        isLoading = true
        error = nil
        
        // In a real app, we would use the QuestionService to load questions
        // For now, we'll just simulate an async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Filter by subject if needed
            let questionIds = self.subjectFilter != nil 
                ? self.lesson.questions.filter { id in
                    // Would check if question matches subject filter
                    return true
                } 
                : self.lesson.questions
            
            // Load questions
            self.getQuestions(ids: questionIds) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let questions):
                        self.questions = questions
                        self.userAnswers = Array(repeating: nil, count: questions.count)
                        self.startTime = Date()
                    case .failure(let error):
                        self.error = error
                    }
                }
            }
        }
    }
    
    /// Get questions by IDs - wrapper around async/await API
    private func getQuestions(ids: [UUID], completion: @escaping (Result<[Question], Error>) -> Void) {
        Task {
            do {
                var loadedQuestions: [Question] = []
                
                // Fetch questions one by one
                for id in ids {
                    if let question = try await questionService.getQuestion(id: id) {
                        loadedQuestions.append(question)
                    }
                }
                
                completion(.success(loadedQuestions))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Submit the current answer
    private func submitAnswer() {
        if let selectedIndex = selectedOptionIndex {
            // Record the answer
            recordAnswer(selectedIndex)
            
            // Show the correct answer
            isShowingAnswer = true
        }
    }
    
    // Navigate to next question
    private func nextQuestion() {
        // If at the end of questions, show summary
        if currentQuestionIndex >= questions.count - 1 {
            completeLesson()
            return
        }
        
        // Reset state for next question
        isShowingAnswer = false
        selectedOptionIndex = nil
        currentQuestionIndex += 1
    }
    
    // Navigate to previous question
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            selectedOptionIndex = userAnswers[currentQuestionIndex]
        }
    }
    
    // Record user's answer and time
    private func recordAnswer(_ answerIndex: Int?) {
        let questionTime = Date().timeIntervalSince(startTime)
        
        // Add to answers and times
        userAnswers[currentQuestionIndex] = answerIndex
        
        // Ensure times array is large enough
        while questionTimes.count <= currentQuestionIndex {
            questionTimes.append(0)
        }
        questionTimes[currentQuestionIndex] = questionTime
        
        // Reset timer for next question
        startTime = Date()
    }
    
    // Complete lesson and update user's progress
    private func completeLesson() {
        isLessonComplete = true
        
        // In a real app, we would update user's completed lessons
        // and send analytics about performance
    }
    
    // Check if option is correct
    private func isCorrectOption(_ index: Int) -> Bool {
        guard let options = questions[currentQuestionIndex].options else { return false }
        let correctAnswer = questions[currentQuestionIndex].correctAnswer
        
        // Check if the option matches correct answer
        if let textValue = options[index].textValue, textValue == correctAnswer {
            return true
        }
        
        // Check if the answer is a letter (A, B, C) and matches the index
        if correctAnswer.count == 1,
           let firstChar = correctAnswer.first,
           firstChar.isLetter,
           let asciiValue = firstChar.asciiValue {
            
            let answerIndex = Int(asciiValue) - Int(Character("A").asciiValue!)
            return answerIndex == index
        }
        
        return false
    }
    
    // Get option background colors
    private func optionBackgroundColor(index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return .green
            } else if index == selectedOptionIndex {
                return .red
            }
        }
        
        return selectedOptionIndex == index ? .blue : .gray
    }
    
    // Get option content background colors
    private func optionContentBackgroundColor(index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return Color.green.opacity(0.1)
            } else if index == selectedOptionIndex {
                return Color.red.opacity(0.1)
            }
        }
        
        return selectedOptionIndex == index ? Color.blue.opacity(0.1) : Color(.systemGray6)
    }
    
    // Get option border colors
    private func optionBorderColor(index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return .green
            } else if index == selectedOptionIndex {
                return .red
            }
        }
        
        return selectedOptionIndex == index ? .blue : Color.clear
    }
    
    // Calculate lesson progress width
    private func calculateProgressWidth() -> CGFloat {
        let total = CGFloat(questions.count)
        let current = CGFloat(currentQuestionIndex + 1)
        let screenWidth = UIScreen.main.bounds.width - 32  // Account for padding
        return (current / total) * screenWidth
    }
    
    // Calculate accuracy percentage
    private func calculateAccuracyPercentage() -> Int {
        let answeredIndices = userAnswers.indices.filter { userAnswers[$0] != nil }
        if answeredIndices.isEmpty { return 0 }
        
        let correctCount = answeredIndices.filter { index in
            guard let answerIndex = userAnswers[index] else { return false }
            let question = questions[index]
            
            // Check if the option matches correct answer
            if let options = question.options,
               let optionText = options[answerIndex].textValue,
               optionText == question.correctAnswer {
                return true
            }
            
            // Check if the answer is a letter (A, B, C) and matches the index
            if question.correctAnswer.count == 1,
               let firstChar = question.correctAnswer.first,
               firstChar.isLetter,
               let asciiValue = firstChar.asciiValue {
                
                let correctIndex = Int(asciiValue) - Int(Character("A").asciiValue!)
                return correctIndex == answerIndex
            }
            
            return false
        }.count
        
        return Int(Double(correctCount) / Double(answeredIndices.count) * 100)
    }
    
    // Format average time
    private func formatAverageTime() -> String {
        let times = questionTimes.filter { $0 > 0 }
        if times.isEmpty { return "0s" }
        
        let avgTime = times.reduce(0, +) / Double(times.count)
        return "\(Int(avgTime))s"
    }
    
    // Check if there are incorrect answers
    private func hasIncorrectAnswers() -> Bool {
        for (index, answerIndex) in userAnswers.enumerated() {
            if let answer = answerIndex, !isCorrectAnswer(questionIndex: index, answerIndex: answer) {
                return true
            }
        }
        return false
    }
    
    // Get indices of incorrect questions
    private func incorrectQuestionIndices() -> [Int] {
        var indices: [Int] = []
        for (index, answerIndex) in userAnswers.enumerated() {
            if let answer = answerIndex, !isCorrectAnswer(questionIndex: index, answerIndex: answer) {
                indices.append(index)
            }
        }
        return indices
    }
    
    // Check if an answer is correct
    private func isCorrectAnswer(questionIndex: Int, answerIndex: Int) -> Bool {
        guard questionIndex < questions.count else { return false }
        
        let question = questions[questionIndex]
        
        // Check if the option matches correct answer
        if let options = question.options,
           answerIndex < options.count,
           let optionText = options[answerIndex].textValue,
           optionText == question.correctAnswer {
            return true
        }
        
        // Check if the answer is a letter (A, B, C) and matches the index
        if question.correctAnswer.count == 1,
           let firstChar = question.correctAnswer.first,
           firstChar.isLetter,
           let asciiValue = firstChar.asciiValue {
            
            let correctIndex = Int(asciiValue) - Int(Character("A").asciiValue!)
            return correctIndex == answerIndex
        }
        
        return false
    }
    
    // Format subject name
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
    
    // Format difficulty level
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
    NavigationView {
        LessonView(
            lesson: Lesson(
                id: UUID(),
                userId: UUID(),
                subject: .arithmetic,
                difficulty: 2,
                questions: [],
                responses: [],
                accuracy: 0.0,
                responseTime: 0.0,
                startedAt: Date(),
                completedAt: nil,
                status: .notStarted
            ),
            user: User(
                name: "Alex",
                avatar: "avatar-1",
                gradeLevel: 3
            )
        )
    }
} 