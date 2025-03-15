import SwiftUI

/// A view that displays all questions from the timo_questions.json file one by one
struct QuestionExampleView: View {
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
                                    withAnimation {
                                        showingAnswer = true
                                    }
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
                                    Button("Next Question") {
                                        nextQuestion()
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button("Show Answer") {
                                        withAnimation {
                                            showingAnswer = true
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                
                                Spacer()
                                
                                Button(action: nextQuestion) {
                                    Label("Next", systemImage: "arrow.right")
                                }
                                .disabled(currentQuestionIndex == questions.count - 1)
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
                let loadedQuestions = try await QuestionService.shared.loadQuestions()
                DispatchQueue.main.async {
                    self.questions = loadedQuestions
                    self.isLoading = false
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
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            resetQuestionState()
        }
    }
    
    /// Navigate to the previous question
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
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
    QuestionExampleView()
} 
