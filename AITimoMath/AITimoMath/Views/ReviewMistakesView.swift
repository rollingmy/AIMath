import SwiftUI

/// View that shows a student's incorrect answers for review and practice
struct ReviewMistakesView: View {
    // MARK: - Properties
    
    /// The current user
    @ObservedObject var userViewModel: UserViewModel
    
    /// State for incorrect questions
    @State private var incorrectQuestions: [Question] = []
    @State private var isLoading = false
    @State private var errorMessage: AlertMessage?
    
    /// State for currently selected question
    @State private var selectedQuestion: Question?
    @State private var showQuestionDetail = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                if isLoading {
                    ProgressView("Loading your mistakes...")
                        .padding()
                } else if incorrectQuestions.isEmpty {
                    // No mistakes found
                    emptyStateSection
                } else {
                    // Mistakes found
                    mistakesListSection
                }
            }
            .padding(.horizontal)
            .navigationTitle("Review Mistakes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadIncorrectQuestions)
            .sheet(isPresented: $showQuestionDetail) {
                if let question = selectedQuestion {
                    QuestionDetailView(
                        question: question,
                        userViewModel: userViewModel,
                        onComplete: { didCorrect in
                            // If the student corrected their mistake, remove from list
                            if didCorrect, let index = incorrectQuestions.firstIndex(where: { $0.id == question.id }) {
                                incorrectQuestions.remove(at: index)
                            }
                        }
                    )
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
        .background(Color("BackgroundLight"))
    }
    
    // MARK: - Component Views
    
    /// Header with explanation text
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learn from past mistakes")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            Text("Revisit questions you previously answered incorrectly to improve your skills and understanding.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Empty state when no mistakes are found
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.bottom, 8)
            
            Text("No mistakes found!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("DarkGray"))
            
            Text("Great job! You haven't made any mistakes yet, or you've already corrected all of them.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Button to start a new lesson
            NavigationLink(destination: DashboardView(userViewModel: userViewModel)) {
                Text("Practice New Lessons")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 16)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// List of incorrect questions for review
    private var mistakesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select a question to review")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("DarkGray"))
            
            // Group by subject
            ForEach(Lesson.Subject.allCases, id: \.self) { subject in
                let subjectQuestions = incorrectQuestions.filter { $0.subject == subject }
                
                if !subjectQuestions.isEmpty {
                    subjectSection(subject: subject, questions: subjectQuestions)
                }
            }
        }
    }
    
    /// Section for questions in a specific subject
    private func subjectSection(subject: Lesson.Subject, questions: [Question]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Subject header
            HStack {
                Circle()
                    .fill(subject.color)
                    .frame(width: 12, height: 12)
                
                Text(subject.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(subject.color)
            }
            .padding(.horizontal)
            
            // Questions in this subject
            ForEach(questions) { question in
                Button(action: {
                    selectedQuestion = question
                    showQuestionDetail = true
                }) {
                    questionRow(question)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Individual question row
    private func questionRow(_ question: Question) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Question difficulty indicator
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Text("\(question.difficulty)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(difficultyColor(question.difficulty))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Question text (truncated)
                Text(question.questionText)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Question metadata
                HStack {
                    Text(question.type == .multipleChoice ? "Multiple Choice" : "Open-Ended")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    /// Load incorrect questions for the current user
    private func loadIncorrectQuestions() {
        isLoading = true
        
        Task {
            do {
                // In a real app, this would come from a persistent store
                // For now, we'll simulate some incorrect questions
                let questions = try await QuestionService.shared.getIncorrectQuestions(for: userViewModel.id)
                
                DispatchQueue.main.async {
                    self.incorrectQuestions = questions
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
    
    /// Get color based on difficulty level
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

// MARK: - Question Detail View

/// View for reviewing and retrying a specific question
struct QuestionDetailView: View {
    // MARK: - Properties
    
    /// The question to review
    let question: Question
    
    /// The current user
    @ObservedObject var userViewModel: UserViewModel
    
    /// Completion handler when done
    let onComplete: (Bool) -> Void
    
    /// Environment to dismiss view
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - State
    
    /// Selected answer (for multiple choice)
    @State private var selectedOptionIndex: Int?
    
    /// User input answer (for open-ended questions)
    @State private var userInputAnswer = ""
    
    /// Whether the answer has been submitted
    @State private var answerSubmitted = false
    
    /// Whether the answer was correct
    @State private var isCorrect = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Question content
                questionCard
                
                // Answer section
                answerSection
                
                // Feedback section (after submission)
                if answerSubmitted {
                    feedbackSection
                }
                
                // Controls section
                controlsSection
            }
            .padding()
        }
        .background(Color("BackgroundLight"))
        .navigationBarTitle("Question Review", displayMode: .inline)
    }
    
    // MARK: - Component Views
    
    /// Header with subject and difficulty info
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Close button
            HStack {
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
                
                Spacer()
                
                // Subject and difficulty
                HStack {
                    Text(question.subject.displayName)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("•")
                    
                    Text("Difficulty \(question.difficulty)")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color("DarkGray"))
                
                Spacer()
            }
        }
    }
    
    /// Question card with text and image if available
    private var questionCard: some View {
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
    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Answer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Group {
                switch question.type {
                case .multipleChoice:
                    // Multiple choice options
                    multipleChoiceSection
                    
                case .openEnded:
                    // Open-ended input
                    openEndedSection
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Multiple choice answer options
    private var multipleChoiceSection: some View {
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
    private var openEndedSection: some View {
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
        }
    }
    
    /// Feedback after answer submission
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isCorrect ? .green : .red)
                
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            Text(isCorrect 
                ? "Great job! You've corrected this mistake."
                : "Let's review the correct answer and try again."
            )
            .font(.system(size: 16))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
            
            Divider()
                .padding(.vertical, 8)
            
            // Correct answer
            VStack(alignment: .leading, spacing: 8) {
                Text("Correct Answer:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(question.correctAnswer)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
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
    
    /// Controls section with submit/done buttons
    private var controlsSection: some View {
        VStack(spacing: 16) {
            if answerSubmitted {
                // Done button
                Button(action: {
                    onComplete(isCorrect)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(isCorrect ? "Done" : "Try Again Later")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isCorrect ? Color.green : Color.blue)
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
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Whether the answer is ready to submit
    private var isReadyToSubmit: Bool {
        switch question.type {
        case .multipleChoice:
            return selectedOptionIndex != nil
        case .openEnded:
            return !userInputAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // MARK: - Helper Methods
    
    /// Submit the current answer
    private func submitAnswer() {
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
            isCorrect = userInputAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == 
                        question.correctAnswer.lowercased()
        }
        
        // Update state
        answerSubmitted = true
    }
}

// MARK: - Preview
struct ReviewMistakesView_Previews: PreviewProvider {
    static var previews: some View {
        let user = User(
            name: "Test Student",
            avatar: "avatar-1",
            gradeLevel: 5
        )
        
        return NavigationView {
            ReviewMistakesView(userViewModel: UserViewModel(user: user))
        }
    }
} 