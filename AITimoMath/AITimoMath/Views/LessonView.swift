import SwiftUI

/// Interactive lesson view that displays questions and handles user responses
struct LessonView: View {
    // MARK: - Properties
    
    /// The lesson to display
    @State var lesson: Lesson
    
    /// The current user
    @ObservedObject var userViewModel: UserViewModel
    
    /// Environment to dismiss view
    @Environment(\.presentationMode) private var presentationMode
    
    /// View model for the lesson
    private let lessonViewModel: LessonViewModel
    
    /// Initialize with lesson and user view model
    init(lesson: Lesson, userViewModel: UserViewModel, lessonViewModel: LessonViewModel) {
        self._lesson = State(initialValue: lesson)
        self.userViewModel = userViewModel
        self.lessonViewModel = lessonViewModel
    }
    
    // MARK: - State
    
    /// Current question index
    @State private var currentQuestionIndex = 0
    
    /// Selected answer (for multiple choice)
    @State private var selectedOptionIndex: Int?
    
    /// User input answer (for open-ended questions)
    @State private var userInputAnswer = ""
    
    /// Whether the answer has been submitted
    @State private var answerSubmitted = false
    
    /// Whether the answer was correct
    @State private var isCorrect = false
    
    /// Whether to show hint
    @State private var showHint = false
    
    /// Whether to show the lesson summary
    @State private var showSummary = false
    
    /// Start time for the current question
    @State private var questionStartTime = Date()
    
    /// Array of response times
    @State private var responseTimes: [TimeInterval] = []
    
    /// Array of question results
    @State private var questionResults: [Bool] = []
    
    /// Loading state
    @State private var isLoading = false
    
    /// Error message
    @State private var errorMessage: AlertMessage?
    
    /// Questions loaded for the lesson
    @State private var loadedQuestions: [Question] = []
    
    /// Computed property for the current question
    private var currentQuestion: Question? {
        guard currentQuestionIndex < loadedQuestions.count else { return nil }
        return loadedQuestions[currentQuestionIndex]
    }
    
    /// Computed property for progress
    private var progressValue: Float {
        guard !loadedQuestions.isEmpty else { return 0 }
        return Float(currentQuestionIndex) / Float(loadedQuestions.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundLight")
                .ignoresSafeArea()
            
            if isLoading {
                // Loading view
                ProgressView("Loading Questions...")
            } else if showSummary {
                // Summary view
                LessonSummaryView(
                    lesson: lesson,
                    userViewModel: userViewModel,
                    questionResults: questionResults,
                    responseTimes: responseTimes,
                    onDismiss: { presentationMode.wrappedValue.dismiss() }
                )
            } else if let question = currentQuestion {
                // Question view
                VStack(spacing: 0) {
                    // Top navigation bar
                    lessonTopBar
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question card
                            questionCard(question)
                            
                            // Answer section
                            answerSection(question)
                            
                            // Hint section (if available)
                            if let hint = question.hint, showHint {
                                hintView(hint)
                            }
                            
                            // Feedback section (after submission)
                            if answerSubmitted {
                                feedbackView(isCorrect: isCorrect)
                            }
                            
                            // Controls section
                            controlsSection(question)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .onAppear {
                    // Reset state for new question
                    resetForNewQuestion()
                }
            } else {
                // Fallback if no questions
                VStack {
                    Text("No questions available")
                        .font(.headline)
                    
                    Button("Return to Dashboard") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadQuestions()
        }
        .alert(item: $errorMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Components
    
    /// Top navigation bar with progress
    private var lessonTopBar: some View {
        VStack(spacing: 4) {
            HStack {
                // Back button
                Button(action: {
                    if answerSubmitted {
                        moveToNextQuestion()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Subject label
                Text(lessonViewModel.subjectDisplayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Close button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Progress bar
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                .frame(height: 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(Color.white)
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    /// Question card view
    private func questionCard(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text(question.questionText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Question image (if available)
            if let image = question.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Answer section based on question type
    private func answerSection(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Answer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Group {
                switch question.type {
                case .multipleChoice:
                    // Multiple choice options
                    multipleChoiceSection(question)
                    
                case .openEnded:
                    // Open-ended input
                    openEndedSection(question)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Multiple choice answer options
    private func multipleChoiceSection(_ question: Question) -> some View {
        VStack(spacing: 12) {
            // First verify options array exists
            if let options = question.options {
                // Then convert to indexed array and use ForEach
                let indexedOptions = options.indices.map { (index: $0, option: options[$0]) }
                
                ForEach(indexedOptions, id: \.index) { pair in
                    let index = pair.index
                    let option = pair.option
                    
                    Button(action: {
                        if !answerSubmitted {
                            selectedOptionIndex = index
                        }
                    }) {
                        HStack {
                            if let textValue = option.textValue {
                                Text(textValue)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            } else if let image = option.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedOptionIndex == index {
                                let imageName = answerSubmitted ? (isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill") : "circle.fill"
                                let imageColor = answerSubmitted ? (isCorrect ? Color.green : Color.red) : Color.blue
                                Image(systemName: imageName)
                                    .foregroundColor(imageColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(selectedOptionIndex == index ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedOptionIndex == index ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(answerSubmitted)
                }
            } else {
                // Fallback for no options
                Text("No options available")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    /// Open-ended answer input
    private func openEndedSection(_ question: Question) -> some View {
        VStack(spacing: 12) {
            TextField("Enter your answer", text: $userInputAnswer)
                .font(.system(size: 16))
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .disabled(answerSubmitted)
            
            if answerSubmitted {
                HStack {
                    Text("Correct answer: \(question.correctAnswer)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    /// Hint section
    private func hintView(_ hint: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hint")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(hint)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow, lineWidth: 1)
        )
    }
    
    /// Feedback after answer submission
    private func feedbackView(isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isCorrect ? .green : .red)
                
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            Text(isCorrect 
                ? "Great job! You got it right."
                : "Don't worry, learning from mistakes is part of the process."
            )
            .font(.system(size: 16))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
            
            if !isCorrect, let correctAnswer = currentQuestion?.correctAnswer {
                Text("Correct answer: \(correctAnswer)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    /// Controls section with submit/next buttons and hint
    private func controlsSection(_ question: Question) -> some View {
        VStack(spacing: 16) {
            if answerSubmitted {
                // Next question button
                Button(action: moveToNextQuestion) {
                    Text(isLastQuestion ? "Finish Lesson" : "Next Question")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Submit answer button
                Button(action: submitAnswer) {
                    Text("Submit Answer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isReadyToSubmit ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isReadyToSubmit)
                
                // Hint button (if available)
                if question.hint != nil && !showHint {
                    Button(action: { showHint = true }) {
                        Text("Show Hint")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Whether the answer is ready to submit
    private var isReadyToSubmit: Bool {
        if let question = currentQuestion {
            switch question.type {
            case .multipleChoice:
                return selectedOptionIndex != nil
            case .openEnded:
                return !userInputAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
        return false
    }
    
    /// Whether this is the last question in the lesson
    private var isLastQuestion: Bool {
        return currentQuestionIndex >= loadedQuestions.count - 1
    }
    
    // MARK: - Helper Methods
    
    /// Load questions for the lesson
    private func loadQuestions() {
        guard loadedQuestions.isEmpty else { return }
        
        isLoading = true
        
        // In a real implementation, we would load questions from a service
        // For now, we'll create some mock questions
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Create sample questions
            var questions: [Question] = []
            
            // Sample arithmetic questions
            if lesson.subject == .arithmetic {
                var question1 = Question(
                    subject: .arithmetic,
                    difficulty: 2,
                    type: .multipleChoice,
                    questionText: "What is 8 + 5?",
                    correctAnswer: "13"
                )
                question1.options = [
                    .text("11"),
                    .text("12"),
                    .text("13"),
                    .text("14")
                ]
                
                let question2 = Question(
                    subject: .arithmetic,
                    difficulty: 2,
                    type: .openEnded,
                    questionText: "If x + 7 = 12, what is x?",
                    correctAnswer: "5"
                )
                
                questions.append(question1)
                questions.append(question2)
            } else {
                // Default questions for other subjects
                var question = Question(
                    subject: lesson.subject,
                    difficulty: 1,
                    type: .multipleChoice,
                    questionText: "Sample question for \(lessonViewModel.subjectDisplayName)",
                    correctAnswer: "Sample answer"
                )
                question.options = [
                    .text("Sample answer"),
                    .text("Wrong answer 1"),
                    .text("Wrong answer 2"),
                    .text("Wrong answer 3")
                ]
                
                questions.append(question)
            }
            
            DispatchQueue.main.async {
                self.loadedQuestions = questions
                self.isLoading = false
            }
        }
    }
    
    /// Reset state for a new question
    private func resetForNewQuestion() {
        selectedOptionIndex = nil
        userInputAnswer = ""
        answerSubmitted = false
        isCorrect = false
        showHint = false
        questionStartTime = Date()
    }
    
    /// Submit the current answer
    private func submitAnswer() {
        guard let question = currentQuestion else { return }
        
        // Calculate response time
        let responseTime = Date().timeIntervalSince(questionStartTime)
        
        // Check if the answer is correct
        switch question.type {
        case .multipleChoice:
            if let selectedOptionIndex = selectedOptionIndex,
               let options = question.options,
               selectedOptionIndex < options.count,
               let selectedAnswer = options[selectedOptionIndex].textValue {
                isCorrect = selectedAnswer == question.correctAnswer
            }
            
        case .openEnded:
            // Simple exact match for open-ended questions
            // In a production app, we would use NLP for more sophisticated matching
            isCorrect = userInputAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == 
                        question.correctAnswer.lowercased()
        }
        
        // Update state
        answerSubmitted = true
        responseTimes.append(responseTime)
        questionResults.append(isCorrect)
    }
    
    /// Move to the next question or finish the lesson
    private func moveToNextQuestion() {
        if isLastQuestion {
            // Finish the lesson
            completeLesson()
        } else {
            // Move to next question
            currentQuestionIndex += 1
            resetForNewQuestion()
        }
    }
    
    /// Complete the lesson and show summary
    private func completeLesson() {
        // Calculate lesson stats
        let totalCorrect = questionResults.filter { $0 }.count
        let accuracy = Float(totalCorrect) / Float(questionResults.count)
        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        // Update lesson with final stats
        lesson.accuracy = accuracy
        lesson.responseTime = averageResponseTime
        
        // Mark lesson as completed and store lesson ID
        userViewModel.addCompletedLesson(lesson.id)
        
        // Show the summary view
        showSummary = true
        
        // In a real implementation, we would update the learning profile in the background
        // For now, we'll just log that we would do this
        print("Would update learning profile for user \(userViewModel.id) with lesson \(lesson.id)")
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct LessonView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            name: "Test Student",
            avatar: "avatar-1",
            gradeLevel: 5
        )
        let userViewModel = UserViewModel(user: user)
        
        let lesson = Lesson(userId: userViewModel.id, subject: .arithmetic)
        let lessonViewModel = LessonViewModel(lesson: lesson)
        
        return LessonView(
            lesson: lesson, 
            userViewModel: userViewModel, 
            lessonViewModel: lessonViewModel
        )
    }
} 