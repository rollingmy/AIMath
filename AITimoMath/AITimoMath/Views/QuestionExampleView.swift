import SwiftUI

/// A view that displays all questions from the timo_questions.json file one by one
struct QuestionExampleView: View {
    // User state
    var user: User
    var onUserUpdate: (User) -> Void
    // Optional filters to constrain the session questions
    var subjectFilter: Lesson.Subject? = nil
    var difficultyFilter: Int? = nil
    
    // Navigation
    @Environment(\.presentationMode) var presentationMode
    
    // State for question navigation and display
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedOptionIndex: Int?
    @State private var showingAnswer = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showMetadata = false
    @State private var questionNumberInput: String = ""
    @State private var showQuestionNumberInput: Bool = false
    @FocusState private var isQuestionNumberInputFocused: Bool
    
    // Session analytics
    @State private var sessionResponses: [Lesson.QuestionResponse] = []
    @State private var questionStartTime: Date = Date()
    
    // Initialize with user and update callback (and optional filters)
    init(user: User, subject: Lesson.Subject? = nil, difficulty: Int? = nil, onUserUpdate: @escaping (User) -> Void) {
        self.user = user
        self.subjectFilter = subject
        self.difficultyFilter = difficulty
        self.onUserUpdate = onUserUpdate
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Loading state
                if isLoading {
                    ProgressView("Loading questions...")
                }
                // Error state
                else if let error = errorMessage {
                    VStack {
                        Text("Error loading questions")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            loadQuestions()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .padding()
                }
                // No questions state
                else if questions.isEmpty {
                    Text("No questions available")
                        .font(.headline)
                }
                // Questions display
                else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Question counter, navigation input and metadata toggle
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        showQuestionNumberInput.toggle()
                                        if showQuestionNumberInput {
                                            questionNumberInput = "\(currentQuestionIndex + 1)"
                                            isQuestionNumberInputFocused = true
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                                            .font(.headline)
                                        Image(systemName: "pencil.circle")
                                            .font(.caption)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showMetadata.toggle()
                                    }
                                }) {
                                    Label(showMetadata ? "Hide Details" : "Show Details", 
                                          systemImage: showMetadata ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            
                            // Question number input field (collapsible)
                            if showQuestionNumberInput {
                                HStack {
                                    Text("Go to question:")
                                        .font(.subheadline)
                                    
                                    TextField("Enter question number", text: $questionNumberInput)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 100)
                                        .focused($isQuestionNumberInputFocused)
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                
                                                Button("Done") {
                                                    isQuestionNumberInputFocused = false
                                                    navigateToQuestionNumber()
                                                }
                                            }
                                        }
                                        .onSubmit {
                                            navigateToQuestionNumber()
                                        }
                                    
                                    Button("Go") {
                                        navigateToQuestionNumber()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .transition(.opacity)
                            }
                            
                            // Subject and difficulty badge
                            HStack {
                                Text(subjectString(questions[currentQuestionIndex].subject))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(subjectColor(questions[currentQuestionIndex].subject).opacity(0.2))
                                    .cornerRadius(8)
                                
                                Text(difficultyString(questions[currentQuestionIndex].difficulty))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(difficultyColor(questions[currentQuestionIndex].difficulty).opacity(0.2))
                                    .cornerRadius(8)
                                
                                Text(questions[currentQuestionIndex].type.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            
                            // Question ID
                            /*Text("ID: \(questions[currentQuestionIndex].id.uuidString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)*/
                            
                            // Metadata section (collapsible)
                            if showMetadata {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Question Details")
                                        .font(.headline)
                                        .padding(.top, 4)
                                    
                                    Divider()
                                    
                                    // Parameters
                                    Group {
                                        Text("Parameters:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("• Elo Rating: \(getEloRating())")
                                        Text("• BKT: pLearn=\(getBKTValue("pLearn")), pGuess=\(getBKTValue("pGuess")), pSlip=\(getBKTValue("pSlip")), pKnown=\(getBKTValue("pKnown"))")
                                            .lineLimit(2)
                                            .font(.caption)
                                        Text("• IRT: discrimination=\(getIRTValue("discrimination")), difficulty=\(getIRTValue("difficulty")), guessing=\(getIRTValue("guessing"))")
                                            .lineLimit(2)
                                            .font(.caption)
                                    }
                                    
                                    Divider()
                                    
                                    // Metadata
                                    Group {
                                        Text("Metadata:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("• Tags: \(getTags().joined(separator: ", "))")
                                            .font(.caption)
                                        Text("• Time Limit: \(getTimeLimit()) seconds")
                                            .font(.caption)
                                        Text("• Points Value: \(getPointsValue())")
                                            .font(.caption)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            // Question view
                            QuestionView(
                                question: questions[currentQuestionIndex],
                                selectedOptionIndex: $selectedOptionIndex,
                                showCorrectAnswer: showingAnswer,
                                onSubmit: {
                                    // Record response
                                    let question = questions[currentQuestionIndex]
                                    var isCorrect = false
                                    var selectedLabel: String? = nil
                                    if let options = question.options,
                                       let selected = selectedOptionIndex,
                                       selected >= 0,
                                       selected < options.count {
                                        // Map selected index to letter label A/B/C/D
                                        let labels = ["A", "B", "C", "D"]
                                        let label = selected < labels.count ? labels[selected] : nil
                                        selectedLabel = label
                                        // Compare label to correct answer key (e.g., "A")
                                        if let label = label {
                                            isCorrect = (label == question.correctAnswer)
                                        }
                                    }
                                    let responseTime = Date().timeIntervalSince(questionStartTime)
                                    let response = Lesson.QuestionResponse(
                                        questionId: question.id,
                                        isCorrect: isCorrect,
                                        responseTime: responseTime,
                                        answeredAt: Date(),
                                        selectedAnswer: selectedLabel
                                    )
                                    sessionResponses.append(response)
                                    
                                    withAnimation { showingAnswer = true }
                                }
                            )
                            
                            // Navigation buttons
                            HStack {
                                Button(action: previousQuestion) {
                                    Label("Previous", systemImage: "arrow.left")
                                }
                                .disabled(currentQuestionIndex == 0)
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                if showingAnswer {
                                    // Check if this is the last question
                                    if currentQuestionIndex == questions.count - 1 {
                                        Button("Complete Session") {
                                            print("Complete Session button tapped")
                                            completeSession()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .foregroundColor(.white)
                                        .background(Color.green)
                                    } else {
                                        Button("Next Question") {
                                            nextQuestion()
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                } else {
                                    Button("Show Answer") {
                                        // If no response recorded yet for this question, record it now
                                        if !hasRecordedResponse(for: questions[currentQuestionIndex].id) {
                                            let question = questions[currentQuestionIndex]
                                            var isCorrect = false
                                            var selectedLabel: String? = nil
                                            if let options = question.options,
                                               let selected = selectedOptionIndex,
                                               selected >= 0,
                                               selected < options.count {
                                                let labels = ["A", "B", "C", "D"]
                                                let label = selected < labels.count ? labels[selected] : nil
                                                selectedLabel = label
                                                if let label = label {
                                                    isCorrect = (label == question.correctAnswer)
                                                }
                                            }
                                            let responseTime = Date().timeIntervalSince(questionStartTime)
                                            let response = Lesson.QuestionResponse(
                                                questionId: question.id,
                                                isCorrect: isCorrect,
                                                responseTime: responseTime,
                                                answeredAt: Date(),
                                                selectedAnswer: selectedLabel
                                            )
                                            sessionResponses.append(response)
                                        }
                                        withAnimation { showingAnswer = true }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if currentQuestionIndex == questions.count - 1 {
                                        print("Complete Session button (right arrow) tapped")
                                        completeSession()
                                    } else {
                                        nextQuestion()
                                    }
                                }) {
                                    Label(currentQuestionIndex == questions.count - 1 ? "Complete" : "Next", 
                                          systemImage: currentQuestionIndex == questions.count - 1 ? "checkmark.circle" : "arrow.right")
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("TIMO Questions")
            .onAppear {
                loadQuestions()
            }
        }
    }
    
    // Helper methods to extract question metadata
    private func getEloRating() -> String {
        guard let jsonData = getQuestionJSONData(),
              let parameters = jsonData["parameters"] as? [String: Any],
              let eloRating = parameters["eloRating"] as? Int else { 
            return "N/A" 
        }
        return "\(eloRating)"
    }
    
    private func getBKTValue(_ key: String) -> String {
        guard let jsonData = getQuestionJSONData(),
              let parameters = jsonData["parameters"] as? [String: Any],
              let bkt = parameters["bkt"] as? [String: Any],
              let value = bkt[key] as? Double else { 
            return "N/A" 
        }
        return String(format: "%.2f", value)
    }
    
    private func getIRTValue(_ key: String) -> String {
        guard let jsonData = getQuestionJSONData(),
              let parameters = jsonData["parameters"] as? [String: Any],
              let irt = parameters["irt"] as? [String: Any],
              let value = irt[key] as? Double else { 
            return "N/A" 
        }
        return String(format: "%.2f", value)
    }
    
    private func getTags() -> [String] {
        guard let jsonData = getQuestionJSONData(),
              let metadata = jsonData["metadata"] as? [String: Any],
              let tags = metadata["tags"] as? [String] else { 
            return [] 
        }
        return tags
    }
    
    private func getTimeLimit() -> String {
        guard let jsonData = getQuestionJSONData(),
              let metadata = jsonData["metadata"] as? [String: Any],
              let timeLimit = metadata["timeLimit"] as? Int else { 
            return "N/A" 
        }
        return "\(timeLimit)"
    }
    
    private func getPointsValue() -> String {
        guard let jsonData = getQuestionJSONData(),
              let metadata = jsonData["metadata"] as? [String: Any],
              let pointsValue = metadata["pointsValue"] as? Int else { 
            return "N/A" 
        }
        return "\(pointsValue)"
    }
    
    private func getQuestionJSONData() -> [String: Any]? {
        guard currentQuestionIndex < questions.count else { return nil }
        
        // This is a hack to get the original JSON data
        // In a real app, you would store this data in the Question model
        guard let url = Bundle.main.url(forResource: "timo_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let questionsArray = json["questions"] as? [[String: Any]],
              currentQuestionIndex < questionsArray.count else {
            return nil
        }
        
        return questionsArray[currentQuestionIndex]
    }
    
    /// Load questions from the JSON file
    private func loadQuestions() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let allQuestions = try await QuestionService.shared.loadQuestions()
                // Apply subject and difficulty filters if provided
                var filtered = allQuestions
                if let sf = subjectFilter {
                    filtered = filtered.filter { $0.subject == sf }
                }
                if let df = difficultyFilter {
                    filtered = filtered.filter { $0.difficulty == df }
                }
                // Ensure we fill up to the daily goal by topping up from same subject (nearest difficulties)
                let target = user.dailyGoal
                var pool = filtered
                if pool.count < target, let sf = subjectFilter {
                    let sameSubject = allQuestions.filter { $0.subject == sf }
                    let base = difficultyFilter ?? 0
                    // nearest difficulty order
                    let order: [Int]
                    if base == 0 {
                        order = [1,2,3,4]
                    } else {
                        order = [base, max(1, base-1), min(4, base+1), max(1, base-2), min(4, base+2)]
                    }
                    for d in order {
                        guard pool.count < target else { break }
                        let extras = sameSubject.filter { $0.difficulty == d && !pool.contains($0) }
                        for q in extras {
                            guard pool.count < target else { break }
                            pool.append(q)
                        }
                    }
                }
                let loadedQuestions = Array(pool.prefix(target))
                DispatchQueue.main.async {
                    self.questions = loadedQuestions
                    self.isLoading = false
                    self.questionStartTime = Date()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Navigate to the next question
    private func nextQuestion() {
        // If no response recorded yet for current question, record now
        if currentQuestionIndex < questions.count && !hasRecordedResponse(for: questions[currentQuestionIndex].id) {
            let question = questions[currentQuestionIndex]
            var isCorrect = false
            var selectedLabel: String? = nil
            if let options = question.options,
               let selected = selectedOptionIndex,
               selected >= 0,
               selected < options.count {
                let labels = ["A", "B", "C", "D"]
                let label = selected < labels.count ? labels[selected] : nil
                selectedLabel = label
                if let label = label {
                    isCorrect = (label == question.correctAnswer)
                }
            }
            let responseTime = Date().timeIntervalSince(questionStartTime)
            let response = Lesson.QuestionResponse(
                questionId: question.id,
                isCorrect: isCorrect,
                responseTime: responseTime,
                answeredAt: Date(),
                selectedAnswer: selectedLabel
            )
            sessionResponses.append(response)
        }
        // Check if this is the last question in the session
        if currentQuestionIndex == questions.count - 1 {
            // Complete the session
            completeSession()
            return
        }
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            // Start timing for the next question
            questionStartTime = Date()
            resetQuestionState()
        }
    }
    
    /// Navigate to the previous question
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            // Ensure we record response for current before moving back
            if !hasRecordedResponse(for: questions[currentQuestionIndex].id) {
                let question = questions[currentQuestionIndex]
                var isCorrect = false
                var selectedLabel: String? = nil
                if let options = question.options,
                   let selected = selectedOptionIndex,
                   selected >= 0,
                   selected < options.count {
                    let labels = ["A", "B", "C", "D"]
                    let label = selected < labels.count ? labels[selected] : nil
                    selectedLabel = label
                    if let label = label {
                        isCorrect = (label == question.correctAnswer)
                    }
                }
                let responseTime = Date().timeIntervalSince(questionStartTime)
                let response = Lesson.QuestionResponse(
                    questionId: question.id,
                    isCorrect: isCorrect,
                    responseTime: responseTime,
                    answeredAt: Date(),
                    selectedAnswer: selectedLabel
                )
                sessionResponses.append(response)
            }
            currentQuestionIndex -= 1
            // Restart timing for previous question
            questionStartTime = Date()
            resetQuestionState()
        }
    }
    
    /// Navigate to a specific question number
    private func navigateToQuestionNumber() {
        if let index = Int(questionNumberInput), index > 0 && index <= questions.count {
            currentQuestionIndex = index - 1
            resetQuestionState()
            
            // Hide the input field and dismiss keyboard
            withAnimation {
                showQuestionNumberInput = false
                isQuestionNumberInputFocused = false
            }
        } else {
            // Show invalid input feedback
            questionNumberInput = ""
        }
    }
    
    /// Reset the question state when navigating
    private func resetQuestionState() {
        selectedOptionIndex = nil
        showingAnswer = false
    }

    /// Check if we already recorded a response for a given question id
    private func hasRecordedResponse(for questionId: UUID) -> Bool {
        return sessionResponses.contains(where: { $0.questionId == questionId })
    }
    
    /// Complete the current session and update user progress
    private func completeSession() {
        // Compute number of questions answered in this session
        let answeredCount = questions.count
        
        // Update user's daily completed questions by answeredCount (matches dailyGoal session)
        var updatedUser = user
        updatedUser.dailyCompletedQuestions += answeredCount
        updatedUser.lastActiveAt = Date()
        
        // Persist lesson summary for analytics (subject, responses)
        Task {
            // Build a minimal lesson snapshot
            var lesson = Lesson(userId: updatedUser.id, subject: questions.first?.subject ?? .arithmetic)
            lesson.questions = questions.map { $0.id }
            lesson.difficulty = questions.first?.difficulty ?? 1
            lesson.status = .completed
            lesson.completedAt = Date()
            // Attach recorded responses with correctness and timing
            lesson.responses = sessionResponses
            // Derive accuracy and avg response time
            let correctCount = sessionResponses.filter { $0.isCorrect }.count
            if !sessionResponses.isEmpty {
                lesson.accuracy = Float(correctCount) / Float(sessionResponses.count)
                lesson.responseTime = sessionResponses.map { $0.responseTime }.reduce(0, +) / Double(sessionResponses.count)
            }
            // Save to Core Data
            try? await PerformanceService.shared.saveLesson(lesson)
        }
        
        // Update the user through the callback
        onUserUpdate(updatedUser)
        
        // Add debug logging to help troubleshoot
        print("Session completed! +\(answeredCount) → Daily progress: \(updatedUser.dailyCompletedQuestions)/\(updatedUser.dailyGoal)")
        
        // Navigate back to the previous view
        presentationMode.wrappedValue.dismiss()
    }
    
    /// Convert subject enum to display string
    private func subjectString(_ subject: Lesson.Subject) -> String {
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
    
    /// Get color for subject
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
    
    /// Convert difficulty int to display string
    private func difficultyString(_ difficulty: Int) -> String {
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
    
    /// Get color for difficulty
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
    QuestionExampleView(
        user: User(name: "Test Student", avatar: "avatar-1", gradeLevel: 5),
        onUserUpdate: { _ in }
    )
} 
