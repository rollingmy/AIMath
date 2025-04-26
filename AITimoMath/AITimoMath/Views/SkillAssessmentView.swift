import SwiftUI

/// View for conducting an initial skill assessment to determine starting difficulty
struct SkillAssessmentView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    // States for the assessment
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var isAnswerSubmitted = false
    @State private var isAssessmentCompleted = false
    @State private var questions: [Question] = []
    @State private var answers: [String] = []
    @State private var correctAnswers = 0
    @State private var assessmentResults: [Lesson.Subject: Int] = [:]
    @State private var isLoading = true
    
    // Questions for each subject
    private let questionsPerSubject = 2
    private let subjects: [Lesson.Subject] = [.arithmetic, .geometry, .numberTheory, .logicalThinking, .combinatorics]
    
    var body: some View {
        VStack {
            if isLoading {
                loadingView
            } else if isAssessmentCompleted {
                resultsView
            } else {
                questionView
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Skill Assessment")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            loadQuestions()
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Preparing your assessment...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // Question view
    private var questionView: some View {
        VStack(spacing: 20) {
            // Progress indicator
            ProgressView(value: Double(currentQuestionIndex), total: Double(questions.count))
                .padding(.horizontal)
            
            // Question counter
            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Subject badge
            if currentQuestionIndex < questions.count {
                Text(formatSubject(questions[currentQuestionIndex].subject))
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(subjectColor(questions[currentQuestionIndex].subject).opacity(0.2))
                    .foregroundColor(subjectColor(questions[currentQuestionIndex].subject))
                    .cornerRadius(20)
            }
            
            // Question text
            if currentQuestionIndex < questions.count {
                Text(questions[currentQuestionIndex].questionText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            
            // Answer options
            ScrollView {
                VStack(spacing: 12) {
                    if currentQuestionIndex < questions.count, let options = questions[currentQuestionIndex].options {
                        ForEach(0..<options.count, id: \.self) { index in
                            Button(action: {
                                if !isAnswerSubmitted {
                                    selectedAnswerIndex = index
                                }
                            }) {
                                HStack {
                                    if let textValue = options[index].textValue {
                                        Text(textValue)
                                            .font(.body)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    if isAnswerSubmitted,
                                       let selectedOption = selectedAnswerIndex != nil ? options[selectedAnswerIndex!].textValue : nil {
                                        
                                        if options[index].textValue == questions[currentQuestionIndex].correctAnswer {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if selectedAnswerIndex == index {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(answerBackground(for: index))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isAnswerSubmitted)
                        }
                    }
                }
                .padding()
            }
            
            // Submit/Next button
            Button(action: {
                if isAnswerSubmitted {
                    // Move to next question
                    moveToNextQuestion()
                } else if selectedAnswerIndex != nil {
                    // Submit current answer
                    submitAnswer()
                }
            }) {
                Text(isAnswerSubmitted ? (currentQuestionIndex < questions.count - 1 ? "Next Question" : "See Results") : "Submit Answer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedAnswerIndex != nil ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(selectedAnswerIndex == nil && !isAnswerSubmitted)
            .padding()
        }
    }
    
    // Results view
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Assessment Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You got \(correctAnswers) out of \(questions.count) questions correct")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Subject breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Text("Subject Breakdown")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(subjects, id: \.self) { subject in
                        let score = assessmentResults[subject] ?? 0
                        let maxScore = questionsPerSubject
                        
                        HStack {
                            Text(formatSubject(subject))
                                .font(.subheadline)
                                .frame(width: 140, alignment: .leading)
                            
                            // Progress bar
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 8)
                                    .foregroundColor(Color(.systemGray5))
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .frame(width: CGFloat(score) / CGFloat(maxScore) * 150, height: 8)
                                    .foregroundColor(subjectColor(subject))
                                    .cornerRadius(4)
                            }
                            .frame(width: 150)
                            
                            Text("\(score)/\(maxScore)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Recommendations
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recommendations")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Find weakest and strongest subjects
                    let weakestSubject = findWeakestSubject()
                    let strongestSubject = findStrongestSubject()
                    
                    if let weakest = weakestSubject {
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Focus on \(formatSubject(weakest))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("We recommend practicing more \(formatSubject(weakest)) problems to improve your skills in this area.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if let strongest = strongestSubject {
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "star")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Strength in \(formatSubject(strongest))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("You're doing great in \(formatSubject(strongest))! Consider trying more advanced problems.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // Save results to user profile and update level
                        updateUserProfile()
                        dismiss()
                    }) {
                        Text("Continue to Dashboard")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Retake assessment
                        resetAssessment()
                    }) {
                        Text("Retake Assessment")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Load assessment questions
    private func loadQuestions() {
        isLoading = true
        
        // In a real app, this would be fetched from a service
        // Here we're creating sample questions for each subject
        var allQuestions: [Question] = []
        
        for subject in subjects {
            let subjectQuestions = createQuestionsForSubject(subject, count: questionsPerSubject)
            allQuestions.append(contentsOf: subjectQuestions)
        }
        
        // Shuffle questions for random order
        questions = allQuestions.shuffled()
        
        // Initialize answers array
        answers = Array(repeating: "", count: questions.count)
        
        // Initialize assessment results
        for subject in subjects {
            assessmentResults[subject] = 0
        }
        
        // Finish loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    // Create questions for a specific subject
    private func createQuestionsForSubject(_ subject: Lesson.Subject, count: Int) -> [Question] {
        var questions: [Question] = []
        
        for i in 0..<count {
            var question: Question
            
            switch subject {
            case .arithmetic:
                if i == 0 {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 2,
                        type: .multipleChoice,
                        questionText: "What is the result of 24 × 7 + 15?",
                        options: [
                            .text("163"),
                            .text("168"),
                            .text("183"),
                            .text("197")
                        ],
                        correctAnswer: "183",
                        hint: "First multiply 24 × 7 = 168, then add 15."
                    )
                } else {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 2,
                        type: .multipleChoice,
                        questionText: "What is the value of 5/8 of 64?",
                        options: [
                            .text("35"),
                            .text("40"),
                            .text("45"),
                            .text("50")
                        ],
                        correctAnswer: "40",
                        hint: "5/8 of 64 = 5 × (64 ÷ 8) = 5 × 8 = 40"
                    )
                }
                
            case .geometry:
                if i == 0 {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 2,
                        type: .multipleChoice,
                        questionText: "What is the area of a rectangle with length 12 cm and width 5 cm?",
                        options: [
                            .text("34 cm²"),
                            .text("60 cm²"),
                            .text("65 cm²"),
                            .text("70 cm²")
                        ],
                        correctAnswer: "60 cm²",
                        hint: "Area of rectangle = length × width = 12 × 5 = 60 cm²"
                    )
                } else {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 3,
                        type: .multipleChoice,
                        questionText: "If a regular hexagon has sides of length 6 cm, what is its perimeter?",
                        options: [
                            .text("30 cm"),
                            .text("36 cm"),
                            .text("42 cm"),
                            .text("48 cm")
                        ],
                        correctAnswer: "36 cm",
                        hint: "Perimeter = number of sides × side length = 6 × 6 = 36 cm"
                    )
                }
                
            case .numberTheory:
                if i == 0 {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 2,
                        type: .multipleChoice,
                        questionText: "What is the prime factorization of 72?",
                        options: [
                            .text("2³ × 3²"),
                            .text("2³ × 3³"),
                            .text("2⁴ × 3"),
                            .text("2² × 3³")
                        ],
                        correctAnswer: "2³ × 3²",
                        hint: "72 = 8 × 9 = 2³ × 3²"
                    )
                } else {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 3,
                        type: .multipleChoice,
                        questionText: "What is the least common multiple (LCM) of 12 and 18?",
                        options: [
                            .text("6"),
                            .text("24"),
                            .text("36"),
                            .text("72")
                        ],
                        correctAnswer: "36",
                        hint: "12 = 2² × 3, 18 = 2 × 3². LCM = 2² × 3² = 36"
                    )
                }
                
            case .logicalThinking:
                if i == 0 {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 2,
                        type: .multipleChoice,
                        questionText: "If all squares are rectangles, and all rectangles are quadrilaterals, which statement must be true?",
                        options: [
                            .text("All quadrilaterals are squares"),
                            .text("All rectangles are squares"),
                            .text("All squares are quadrilaterals"),
                            .text("No quadrilaterals are squares")
                        ],
                        correctAnswer: "All squares are quadrilaterals",
                        hint: "This is a logical inference question. If A→B and B→C, then A→C."
                    )
                } else {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 3,
                        type: .multipleChoice,
                        questionText: "If Alice is taller than Bob, and Bob is taller than Charlie, which statement must be true?",
                        options: [
                            .text("Charlie is taller than Alice"),
                            .text("Alice is taller than Charlie"),
                            .text("Bob is taller than Alice"),
                            .text("None of the above")
                        ],
                        correctAnswer: "Alice is taller than Charlie",
                        hint: "This is transitive logic. If A > B and B > C, then A > C."
                    )
                }
                
            case .combinatorics:
                if i == 0 {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 2,
                        type: .multipleChoice,
                        questionText: "How many different 3-digit numbers can be formed using the digits 1, 2, 3, 4, 5 without repeating any digit?",
                        options: [
                            .text("10"),
                            .text("60"),
                            .text("120"),
                            .text("125")
                        ],
                        correctAnswer: "60",
                        hint: "5 choices for first digit × 4 choices for second digit × 3 choices for third digit = 60"
                    )
                } else {
                    question = Question(
                        id: UUID(),
                        subject: subject,
                        difficulty: 3,
                        type: .multipleChoice,
                        questionText: "In how many ways can 5 different books be arranged on a shelf?",
                        options: [
                            .text("15"),
                            .text("25"),
                            .text("120"),
                            .text("125")
                        ],
                        correctAnswer: "120",
                        hint: "This is a permutation of 5 items: 5! = 5 × 4 × 3 × 2 × 1 = 120"
                    )
                }
            }
            
            questions.append(question)
        }
        
        return questions
    }
    
    // Submit answer for the current question
    private func submitAnswer() {
        guard let selectedIndex = selectedAnswerIndex,
              currentQuestionIndex < questions.count,
              let options = questions[currentQuestionIndex].options,
              selectedIndex < options.count else { return }
        
        isAnswerSubmitted = true
        
        let currentQuestion = questions[currentQuestionIndex]
        let selectedAnswer = options[selectedIndex].textValue ?? ""
        answers[currentQuestionIndex] = selectedAnswer
        
        // Check if answer is correct
        if selectedAnswer == currentQuestion.correctAnswer {
            correctAnswers += 1
            
            // Update result for this question's subject
            if let currentScore = assessmentResults[currentQuestion.subject] {
                assessmentResults[currentQuestion.subject] = currentScore + 1
            }
        }
    }
    
    // Move to the next question
    private func moveToNextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            isAnswerSubmitted = false
        } else {
            // Assessment completed
            isAssessmentCompleted = true
        }
    }
    
    // Reset the assessment to start over
    private func resetAssessment() {
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        isAnswerSubmitted = false
        isAssessmentCompleted = false
        correctAnswers = 0
        
        // Reset assessment results
        for subject in subjects {
            assessmentResults[subject] = 0
        }
        
        // Shuffle questions again
        questions = questions.shuffled()
    }
    
    // Update user profile based on assessment results
    private func updateUserProfile() {
        // Update user's subject proficiency levels based on assessment
        for (subject, score) in assessmentResults {
            let proficiencyLevel = calculateProficiencyLevel(score: score, maxScore: questionsPerSubject)
            // In a real app, we would update the user's profile
            // userViewModel.updateProficiency(for: subject, level: proficiencyLevel)
        }
        
        // Create a completed assessment lesson
        let assessmentLesson = Lesson(
            id: UUID(),
            userId: userViewModel.user.id,
            subject: .combinatorics, // Just a placeholder for the assessment
            difficulty: 2,
            questions: questions.map { $0.id },
            responses: createResponsesFromAnswers(),
            accuracy: Float(correctAnswers) / Float(questions.count),
            responseTime: 0, // Not tracked in assessment
            startedAt: Date().addingTimeInterval(-600), // Assume it took 10 minutes
            completedAt: Date(),
            status: .completed
        )
        
        // Add the assessment to completed lessons
        var updatedUser = userViewModel.user
        updatedUser.completedLessons.append(assessmentLesson.id)
        // Update the user view model with the modified user
        userViewModel.user = updatedUser
        userViewModel.objectWillChange.send()
    }
    
    // Create response objects from user's answers
    private func createResponsesFromAnswers() -> [Lesson.QuestionResponse] {
        var responses: [Lesson.QuestionResponse] = []
        
        for (index, question) in questions.enumerated() {
            let userAnswer = answers[index]
            let isCorrect = userAnswer == question.correctAnswer
            
            responses.append(Lesson.QuestionResponse(
                questionId: question.id,
                isCorrect: isCorrect,
                responseTime: 30, // Default time spent per question (not tracked in this UI)
                answeredAt: Date()
            ))
        }
        
        return responses
    }
    
    // Calculate proficiency level based on score
    private func calculateProficiencyLevel(score: Int, maxScore: Int) -> Int {
        let percentage = Float(score) / Float(maxScore)
        
        if percentage >= 0.9 {
            return 3 // Advanced
        } else if percentage >= 0.7 {
            return 2 // Intermediate
        } else {
            return 1 // Beginner
        }
    }
    
    // Find the weakest subject
    private func findWeakestSubject() -> Lesson.Subject? {
        return assessmentResults.min(by: { $0.value < $1.value })?.key
    }
    
    // Find the strongest subject
    private func findStrongestSubject() -> Lesson.Subject? {
        return assessmentResults.max(by: { $0.value < $1.value })?.key
    }
    
    // Format the subject for display
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
    
    // Get background color for answer option
    private func answerBackground(for index: Int) -> Color {
        if isAnswerSubmitted {
            if let options = questions[currentQuestionIndex].options {
                // Directly access the correctAnswer without conditional binding
                let correctAnswer = questions[currentQuestionIndex].correctAnswer
                
                if options[index].textValue == correctAnswer {
                    return Color.green.opacity(0.2)
                } else if selectedAnswerIndex == index {
                    return Color.red.opacity(0.2)
                }
            }
        } else if selectedAnswerIndex == index {
            return Color.blue.opacity(0.2)
        }
        
        return Color(.systemGray6)
    }
    
    // Get color for a subject
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
}

struct SkillAssessmentView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            name: "Test User",
            avatar: "avatar1",
            gradeLevel: 3
        )
        NavigationView {
            SkillAssessmentView(userViewModel: UserViewModel(user: user))
        }
    }
} 