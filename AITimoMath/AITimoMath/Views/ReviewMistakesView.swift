import SwiftUI

/// View for reviewing past incorrect answers
struct ReviewMistakesView: View {
    @ObservedObject var userViewModel: UserViewModel
    @State private var selectedSubject: Lesson.Subject? = nil
    @State private var showingQuestionDetail = false
    @State private var selectedQuestion: Question? = nil
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var mistakeQuestions: [Question] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                searchBar
                
                // Subject filter
                subjectFilterSection
                
                if isLoading {
                    loadingView
                } else if mistakeQuestions.isEmpty {
                    emptyStateView
                } else {
                    // List of mistakes
                    mistakesList
                }
            }
            .padding(.horizontal)
            .navigationTitle("Review Mistakes")
            .onAppear {
                loadMistakes()
            }
            .sheet(isPresented: $showingQuestionDetail) {
                if let question = selectedQuestion {
                    MistakeDetailView(question: question, userViewModel: userViewModel)
                }
            }
        }
    }
    
    // Search bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search mistakes", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) { oldValue, newValue in
                    filterMistakes()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    filterMistakes()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Subject filter
    private var subjectFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All subjects button
                Button(action: {
                    selectedSubject = nil
                    filterMistakes()
                }) {
                    Text("All")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedSubject == nil ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedSubject == nil ? .white : .primary)
                        .cornerRadius(20)
                }
                
                // Subject filter buttons
                ForEach([Lesson.Subject.arithmetic, .geometry, .numberTheory, .logicalThinking, .combinatorics], id: \.self) { subject in
                    Button(action: {
                        selectedSubject = subject
                        filterMistakes()
                    }) {
                        Text(formatSubject(subject))
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedSubject == subject ? subjectColor(subject) : Color(.systemGray5))
                            .foregroundColor(selectedSubject == subject ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your mistakes...")
                .font(.headline)
                .padding()
            Spacer()
        }
    }
    
    // Empty state
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
            
            Text("No Mistakes Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if selectedSubject != nil {
                Text("You haven't made any mistakes in this subject yet, or try a different filter.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
            } else if !searchText.isEmpty {
                Text("No mistakes match your search. Try different keywords.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
            } else {
                Text("Keep practicing to identify areas for improvement. Your mistakes will appear here for review.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
        }
    }
    
    // List of mistakes
    private var mistakesList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(filteredMistakes, id: \.id) { question in
                    Button(action: {
                        selectedQuestion = question
                        showingQuestionDetail = true
                    }) {
                        mistakeCard(question)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical)
        }
    }
    
    // Mistake card view
    private func mistakeCard(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Subject and difficulty
            HStack {
                // Subject tag
                Text(formatSubject(question.subject))
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(subjectColor(question.subject).opacity(0.2))
                    .foregroundColor(subjectColor(question.subject))
                    .cornerRadius(10)
                
                Spacer()
                
                // Difficulty
                HStack(spacing: 3) {
                    ForEach(0..<question.difficulty, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    ForEach(0..<(3-question.difficulty), id: \.self) { _ in
                        Image(systemName: "star")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Date from metadata if available
                if let date = getMistakeDate(for: question) {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Question text
            Text(question.questionText)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(.bottom, 5)
            
            // Image if available
            if let imageData = question.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(8)
                    .padding(.bottom, 5)
            }
            
            // Bottom section with your answer vs correct answer
            HStack(alignment: .center) {
                // Your incorrect answer
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Answer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(getIncorrectAnswer(for: question) ?? "")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                Spacer()
                
                // Correct answer
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Correct Answer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(question.correctAnswer)
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Helper methods
    
    // Load mistakes from completed lessons
    private func loadMistakes() {
        isLoading = true
        mistakeQuestions = []
        
        // Use the shared instance of QuestionService
        let questionService = QuestionService.shared
        var loadedQuestions: [Question] = []
        let incorrectResponses = getAllIncorrectResponses()
        
        // Perform async loading with Task
        Task {
            // Track loading progress for user feedback
            var loadedCount = 0
            
            for response in incorrectResponses {
                do {
                    if let question = try await questionService.getQuestion(id: response.questionId) {
                        // Add metadata to the question to identify when the mistake was made
                        var questionWithMetadata = question
                        if let metadata = question.metadata {
                            var updatedMetadata = metadata
                            updatedMetadata["mistakeDate"] = response.answeredAt.timeIntervalSince1970
                            questionWithMetadata.metadata = updatedMetadata
                        } else {
                            // If no metadata exists, create new metadata
                            var newMetadata: [String: Any] = [:]
                            newMetadata["mistakeDate"] = response.answeredAt.timeIntervalSince1970
                            questionWithMetadata.metadata = newMetadata
                        }
                        
                        loadedQuestions.append(questionWithMetadata)
                    }
                } catch {
                    print("Error loading question \(response.questionId): \(error)")
                }
                
                loadedCount += 1
                
                // Update UI periodically for better user experience
                if loadedCount % 5 == 0 || loadedCount == incorrectResponses.count {
                    DispatchQueue.main.async {
                        self.mistakeQuestions = loadedQuestions
                        if loadedCount == incorrectResponses.count {
                            self.isLoading = false
                        }
                    }
                }
            }
            
            // Final update if there are no questions or loading finished quickly
            DispatchQueue.main.async {
                self.mistakeQuestions = loadedQuestions
                self.isLoading = false
            }
        }
    }
    
    // Filter mistakes based on search text and selected subject
    private func filterMistakes() {
        // No need to reload if we're just filtering
        if !isLoading {
            // Will use the full list from loadMistakes() and filter in filteredMistakes computed property
        }
    }
    
    // Get all incorrect responses from completed lessons
    private func getAllIncorrectResponses() -> [Lesson.QuestionResponse] {
        var incorrectResponses: [Lesson.QuestionResponse] = []
        
        // Get mock lessons from completed lesson IDs
        let mockLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        // Get incorrect responses from lessons
        for lesson in mockLessons {
            for response in lesson.responses {
                if !response.isCorrect {
                    incorrectResponses.append(response)
                }
            }
        }
        
        // Sort by most recent mistakes first
        return incorrectResponses.sorted(by: { $0.answeredAt > $1.answeredAt })
    }
    
    // Get incorrect answer for a question
    private func getIncorrectAnswer(for question: Question) -> String? {
        // Since QuestionResponse doesn't have a userAnswer property,
        // we'll return a placeholder message
        let mockLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        for lesson in mockLessons {
            for response in lesson.responses {
                if response.questionId == question.id && !response.isCorrect {
                    return "Unknown (response tracking only stores correctness)"
                }
            }
        }
        return nil
    }
    
    // Get mistake date from question metadata
    private func getMistakeDate(for question: Question) -> Date? {
        if let metadata = question.metadata,
           let mistakeDateInterval = metadata["mistakeDate"] as? TimeInterval {
            return Date(timeIntervalSince1970: mistakeDateInterval)
        }
        
        // If no metadata, default to a recent date
        return Date().addingTimeInterval(-Double.random(in: 0...86400)) // Random time within last 24 hours
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
    
    // Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Computed property for filtered mistakes
    private var filteredMistakes: [Question] {
        mistakeQuestions.filter { question in
            // Apply subject filter if selected
            let subjectMatch = selectedSubject == nil || question.subject == selectedSubject
            
            // Apply search filter if text entered
            let searchMatch = searchText.isEmpty || 
                question.questionText.localizedCaseInsensitiveContains(searchText) ||
                question.correctAnswer.localizedCaseInsensitiveContains(searchText)
            
            return subjectMatch && searchMatch
        }
    }
}

// Detail view for a mistake
struct MistakeDetailView: View {
    let question: Question
    let userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Subject and difficulty
                    HStack {
                        Text(formatSubject(question.subject))
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(subjectColor(question.subject).opacity(0.2))
                            .foregroundColor(subjectColor(question.subject))
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        // Difficulty stars
                        HStack(spacing: 4) {
                            ForEach(0..<question.difficulty, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            ForEach(0..<(3-question.difficulty), id: \.self) { _ in
                                Image(systemName: "star")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Question text
                    Text(question.questionText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 8)
                    
                    // Question image if available
                    if let imageData = question.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .padding(.bottom, 10)
                    }
                    
                    Divider()
                    
                    // Incorrect answer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Answer")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(getIncorrectAnswer(for: question) ?? "")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // Correct answer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correct Answer")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text(question.correctAnswer)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    // Hint if available
                    if let hint = question.hint, !hint.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hint")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text(hint)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Related questions or concepts would go here
                    
                    // Practice button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                        // Here you would navigate to practice similar questions
                    }) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                            Text("Practice Similar Questions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
            .navigationTitle("Mistake Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // Get incorrect answer from user history
    private func getIncorrectAnswer(for question: Question) -> String? {
        // Since QuestionResponse doesn't have a userAnswer property,
        // we'll return a placeholder message
        let mockLessons = getMockLessonsFromIds(userViewModel.user.completedLessons)
        
        for lesson in mockLessons {
            for response in lesson.responses {
                if response.questionId == question.id && !response.isCorrect {
                    return "Unknown (response tracking only stores correctness)"
                }
            }
        }
        return nil
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

struct ReviewMistakesView_Previews: PreviewProvider {
    static var previews: some View {
        let user = createSampleUser()
        ReviewMistakesView(userViewModel: UserViewModel(user: user))
    }
    
    static func createSampleUser() -> User {
        // Create a User with proper initialization parameters
        var user = User(
            name: "Test User",
            avatar: "avatar1",
            gradeLevel: 3
        )
        
        // Add sample completed lessons IDs
        for _ in 0..<5 {
            user.completedLessons.append(UUID())
        }
        
        return user
    }
} 