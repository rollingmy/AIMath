import SwiftUI

/// View for conducting an initial skill assessment to determine starting difficulty
struct SkillAssessmentView: View {
    // User data
    @ObservedObject var userViewModel: UserViewModel
    @Binding var isAssessmentComplete: Bool
    
    // State
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedOptionIndex: Int?
    @State private var userAnswers: [Int?] = []
    @State private var isShowingAnswer = false
    @State private var isLoading = true
    @State private var error: Error?
    
    // Constants
    private let maxQuestions = 5
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    
    // Services
    private let questionService = QuestionService.shared
    
    // For backward compatibility with simple preview methods
    init(user: User, isAssessmentComplete: Binding<Bool>) {
        self.userViewModel = UserViewModel(user: user)
        self._isAssessmentComplete = isAssessmentComplete
    }
    
    // For use with the ViewModel
    init(userViewModel: UserViewModel, isAssessmentComplete: Binding<Bool>) {
        self.userViewModel = userViewModel
        self._isAssessmentComplete = isAssessmentComplete
    }
    
    var body: some View {
        VStack {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if questions.isEmpty {
                noQuestionsView
            } else {
                assessmentContentView
            }
        }
        .navigationTitle("Skill Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Skip") {
                    // Skip assessment and use default difficulty
                    skipAssessment()
                }
            }
        }
        .onAppear {
            loadAssessmentQuestions()
        }
    }
    
    // MARK: - Sub Views
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Setting up your assessment...")
                .font(.headline)
            
            Text("We're preparing a few questions to help personalize your learning experience.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // Error view
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load assessment")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadAssessmentQuestions()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Skip Assessment") {
                skipAssessment()
            }
            .padding(.top, 10)
        }
    }
    
    // No questions view
    private var noQuestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No assessment questions available")
                .font(.headline)
            
            Text("We'll start you with our standard difficulty level.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Continue to Dashboard") {
                skipAssessment()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // Main assessment content
    private var assessmentContentView: some View {
        VStack(spacing: 20) {
            // Progress indicator
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(maxQuestions))
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            
            Text("Question \(currentQuestionIndex + 1) of \(maxQuestions)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Question text
                    Text(questions[currentQuestionIndex].questionText)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Question image if any
                    if let image = questions[currentQuestionIndex].image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Answer options
                    if let options = questions[currentQuestionIndex].options, !options.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(0..<options.count, id: \.self) { index in
                                Button(action: {
                                    if !isShowingAnswer {
                                        selectedOptionIndex = index
                                        // Record the answer
                                        userAnswers[currentQuestionIndex] = index
                                        
                                        // Show answer feedback briefly
                                        isShowingAnswer = true
                                        
                                        // Schedule moving to next question automatically
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            if currentQuestionIndex < maxQuestions - 1 {
                                                nextQuestion()
                                            } else {
                                                completeAssessment()
                                            }
                                        }
                                    }
                                }) {
                                    HStack {
                                        // Option letter (A, B, C, etc.)
                                        Text("\(Character(UnicodeScalar(65 + index)!))")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 30, height: 30)
                                            .background(
                                                Circle()
                                                    .fill(optionColor(index))
                                            )
                                        
                                        // Option text
                                        if let text = options[index].textValue {
                                            Text(text)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        // Show check/x mark only when answer is shown
                                        if isShowingAnswer {
                                            if isCorrectOption(index) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            } else if index == selectedOptionIndex {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(optionBackground(index))
                                    .cornerRadius(12)
                                }
                                .disabled(isShowingAnswer)
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            
            // Skip button for this question
            if !isShowingAnswer {
                Button("I don't know") {
                    // Record nil answer
                    userAnswers[currentQuestionIndex] = nil
                    
                    // Move to next question
                    if currentQuestionIndex < maxQuestions - 1 {
                        nextQuestion()
                    } else {
                        completeAssessment()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Load sample assessment questions
    private func loadAssessmentQuestions() {
        isLoading = true
        error = nil
        
        // In a real app, we would use QuestionService to fetch appropriate 
        // assessment questions of varying difficulties
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create sample questions for different subjects and difficulties
            var assessmentQuestions: [Question] = []
            
            // Sample question 1 (Arithmetic - Easy)
            var q1 = Question(
                subject: .arithmetic,
                difficulty: 1,
                type: .multipleChoice,
                questionText: "What is 25 + 17?",
                correctAnswer: "42"
            )
            q1.options = [
                .text("39"),
                .text("41"),
                .text("42"),
                .text("43")
            ]
            assessmentQuestions.append(q1)
            
            // Sample question 2 (Logical Thinking - Medium)
            var q2 = Question(
                subject: .logicalThinking,
                difficulty: 2,
                type: .multipleChoice,
                questionText: "If today is Monday, what day will it be after 15 days?",
                correctAnswer: "Tuesday"
            )
            q2.options = [
                .text("Monday"),
                .text("Tuesday"),
                .text("Wednesday"),
                .text("Thursday")
            ]
            assessmentQuestions.append(q2)
            
            // Sample question 3 (Number Theory - Medium)
            var q3 = Question(
                subject: .numberTheory,
                difficulty: 2,
                type: .multipleChoice,
                questionText: "Which of these numbers is a prime number?",
                correctAnswer: "23"
            )
            q3.options = [
                .text("21"),
                .text("22"),
                .text("23"),
                .text("24")
            ]
            assessmentQuestions.append(q3)
            
            // Sample question 4 (Geometry - Hard)
            var q4 = Question(
                subject: .geometry,
                difficulty: 3,
                type: .multipleChoice,
                questionText: "What is the sum of angles in a triangle?",
                correctAnswer: "180 degrees"
            )
            q4.options = [
                .text("90 degrees"),
                .text("180 degrees"),
                .text("270 degrees"),
                .text("360 degrees")
            ]
            assessmentQuestions.append(q4)
            
            // Sample question 5 (Combinatorics - Hard)
            var q5 = Question(
                subject: .combinatorics,
                difficulty: 3,
                type: .multipleChoice,
                questionText: "How many different ways can you arrange the letters in the word 'MATH'?",
                correctAnswer: "24"
            )
            q5.options = [
                .text("4"),
                .text("16"),
                .text("24"),
                .text("64")
            ]
            assessmentQuestions.append(q5)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.questions = assessmentQuestions
                self.userAnswers = Array(repeating: nil, count: assessmentQuestions.count)
                self.isLoading = false
            }
        }
    }
    
    // Move to next question
    private func nextQuestion() {
        isShowingAnswer = false
        selectedOptionIndex = nil
        currentQuestionIndex += 1
    }
    
    // Complete the assessment
    private func completeAssessment() {
        // Calculate performance
        let performanceScore = calculatePerformance()
        
        // Determine appropriate difficulty level
        let recommendedDifficulty = determineRecommendedDifficulty(score: performanceScore)
        
        // Update user's difficulty setting
        // In a real app, we'd save this to the user's profile
        userViewModel.updateDifficultyLevel(recommendedDifficulty)
        
        // Mark assessment as complete
        isAssessmentComplete = true
        dismiss()
    }
    
    // Skip the assessment
    private func skipAssessment() {
        // Set default difficulty level
        userViewModel.updateDifficultyLevel(.adaptive)
        
        // Mark assessment as complete
        isAssessmentComplete = true
        dismiss()
    }
    
    // Calculate performance score (0.0 - 1.0)
    private func calculatePerformance() -> Double {
        var correctCount = 0
        var totalAnswered = 0
        
        for (index, answer) in userAnswers.enumerated() {
            guard let userAnswer = answer else { continue }
            
            totalAnswered += 1
            if isCorrectAnswer(questionIndex: index, answerIndex: userAnswer) {
                correctCount += 1
            }
        }
        
        return totalAnswered > 0 ? Double(correctCount) / Double(totalAnswered) : 0.0
    }
    
    // Determine recommended difficulty based on performance
    private func determineRecommendedDifficulty(score: Double) -> User.DifficultyLevel {
        if score < 0.3 {
            return .beginner
        } else if score < 0.7 {
            return .adaptive
        } else {
            return .advanced
        }
    }
    
    // Check if option is correct for current question
    private func isCorrectOption(_ index: Int) -> Bool {
        guard let options = questions[currentQuestionIndex].options,
              index < options.count else { return false }
        
        let correctAnswer = questions[currentQuestionIndex].correctAnswer
        
        if let optionText = options[index].textValue, optionText == correctAnswer {
            return true
        }
        
        return false
    }
    
    // Check if answer is correct for specific question
    private func isCorrectAnswer(questionIndex: Int, answerIndex: Int) -> Bool {
        guard questionIndex < questions.count,
              let options = questions[questionIndex].options,
              answerIndex < options.count else { return false }
        
        let correctAnswer = questions[questionIndex].correctAnswer
        
        if let optionText = options[answerIndex].textValue, optionText == correctAnswer {
            return true
        }
        
        return false
    }
    
    // Get color for option button
    private func optionColor(_ index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return .green
            } else if index == selectedOptionIndex {
                return .red
            }
        }
        
        return selectedOptionIndex == index ? .blue : .gray
    }
    
    // Get background for option button
    private func optionBackground(_ index: Int) -> Color {
        if isShowingAnswer {
            if isCorrectOption(index) {
                return Color.green.opacity(0.1)
            } else if index == selectedOptionIndex {
                return Color.red.opacity(0.1)
            }
        }
        
        return selectedOptionIndex == index ? Color.blue.opacity(0.1) : Color(.systemGray6)
    }
}

#Preview {
    let user = User(
        name: "Alex",
        avatar: "avatar-1",
        gradeLevel: 3
    )
    SkillAssessmentView(user: user, isAssessmentComplete: .constant(false))
} 