import SwiftUI

struct MistakesReviewView: View {
    @ObservedObject var user: User
    @State private var incorrectQuestions: [Question] = []
    // Map questionId -> selected answer label recorded in responses
    @State private var userAnswers: [UUID: String] = [:]
    @State private var isLoading = true
    @State private var selectedQuestion: Question?
    @State private var showingExplanation = false
    @State private var reviewedQuestionIds: Set<UUID> = []
    @Environment(\.presentationMode) private var presentationMode
    
    private enum Scope: String, CaseIterable { case lastSession = "Last session", allTime = "All time" }
    @State private var selectedScope: Scope = .lastSession
    
    // Display chunk size to keep review short and focused
    private let chunkSize = 3
    
    // Function to load incorrect questions from the user's actual history
    private func loadIncorrectQuestions() {
        isLoading = true
        
        Task {
            do {
                // Load actual incorrect questions from user's lesson history
                let performanceService = PerformanceService.shared
                let questions = try await performanceService.loadIncorrectQuestions(userId: user.id)
                // Build user answer map from latest completed lessons
                if let lessons = try? await performanceService.loadUserLessonHistory(userId: user.id) {
                    var answers: [UUID: String] = [:]
                    for lesson in lessons {
                        for resp in lesson.responses where !resp.isCorrect {
                            if let sel = resp.selectedAnswer {
                                answers[resp.questionId] = sel
                            }
                        }
                    }
                    self.userAnswers = answers
                }
                
                await MainActor.run {
                    self.incorrectQuestions = questions
                    self.isLoading = false
                    print("Loaded \(questions.count) incorrect questions for review")
                }
            } catch {
                print("Error loading incorrect questions: \(error)")
                await MainActor.run {
                    self.incorrectQuestions = []
                    self.isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            // Header
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Mistakes to Review")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Practice these questions to improve your understanding")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Scope selector
                Picker("Scope", selection: $selectedScope) {
                    ForEach(Scope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if incorrectQuestions.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                    
                    Text("Great job!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You don't have any mistakes to review")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                // Determine questions to show based on scope and chunk size (stable ordering)
                let scopedQuestions: [Question] = {
                    if selectedScope == .allTime { return incorrectQuestions }
                    // Fallback heuristic for "Last session": show a recent subset
                    // Keep the same subset while the source list is unchanged to avoid progress reset.
                    return Array(incorrectQuestions.sorted { $0.id.uuidString < $1.id.uuidString }
                        .prefix(max(chunkSize * 2, chunkSize)))
                }()
                let displayQuestions = Array(scopedQuestions.prefix(chunkSize))
                let progressValue = displayQuestions.isEmpty ? 0 : Double(reviewedQuestionIds.intersection(displayQuestions.map { $0.id }).count) / Double(displayQuestions.count)
                
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progressValue)
                    Text("Reviewed \(reviewedQuestionIds.intersection(displayQuestions.map { $0.id }).count)/\(displayQuestions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // List of incorrect questions
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(displayQuestions) { question in
                            let userAnswer = userAnswers[question.id]
                            QuestionReviewCard(
                                question: question,
                                userAnswerLabel: userAnswer,
                                onTap: {
                                    self.selectedQuestion = question
                                    self.showingExplanation = true
                                }
                            )
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
                
                // Mark complete button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(reviewedQuestionIds.intersection(displayQuestions.map { $0.id }).count >= displayQuestions.count ? "Mark complete" : "Keep reviewing"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(reviewedQuestionIds.intersection(displayQuestions.map { $0.id }).count >= displayQuestions.count ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(reviewedQuestionIds.intersection(displayQuestions.map { $0.id }).count < displayQuestions.count)
                .padding()
            }
        }
        .navigationTitle("Review Mistakes")
        .sheet(isPresented: $showingExplanation) {
            if let question = selectedQuestion {
                ExplanationView(question: question) {
                    // Mark this question as reviewed when user taps Got it / Try again
                    reviewedQuestionIds.insert(question.id)
                }
            }
        }
        .onAppear {
            loadIncorrectQuestions()
        }
        .refreshable {
            loadIncorrectQuestions()
        }
    }
}

// MARK: - QuestionReviewCard
struct QuestionReviewCard: View {
    let question: Question
    let userAnswerLabel: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Subject and difficulty tags
                HStack {
                    Text(question.subject.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(getDifficultyText(question.difficulty))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Show when the question was answered incorrectly (mock date)
                    Text("2 days ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Question preview (limit to 2 lines)
                Text(question.questionText.split(separator: "\n").first?.description ?? "")
                    .font(.subheadline)
                    .lineLimit(2)
                    .padding(.top, 5)
                
                HStack {
                    // Wrong answer that was given
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Your answer: \(userAnswerLabel ?? "—")")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text("View Explanation")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Show recorded wrong answer label if available
    private func getWrongAnswer(for question: Question) -> String {
        // Attempt to access parent state's userAnswers via environment is not possible here.
        // Instead, display placeholder and let parent inject via label below (kept compat).
        return ""
    }
    
    // Convert difficulty integer to text
    private func getDifficultyText(_ difficulty: Int) -> String {
        switch difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        case 4: return "Olympiad"
        default: return "Medium"
        }
    }
}

// MARK: - ExplanationView
struct ExplanationView: View {
    let question: Question
    var onReviewed: (() -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question text
                    Text(question.questionText)
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    // Options (if multiple choice)
                    if question.type == .multipleChoice, let options = question.options {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(0..<options.count, id: \.self) { index in
                                HStack(alignment: .top) {
                                    let option = ["A", "B", "C", "D"][index]
                                    let isCorrect = option == question.correctAnswer
                                    
                                    Text(option)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(isCorrect ? Color.green : Color.gray)
                                        .cornerRadius(12)
                                    
                                    Text(options[index].textValue ?? "Option \(option)")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Divider
                    Divider()
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Explanation")
                            .font(.headline)
                        
                        Text(question.hint ?? "This is the explanation for the question. The correct answer is \(question.correctAnswer).")
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            onReviewed?()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Got it")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Allow skipping but still count towards completion to reduce friction
                            onReviewed?()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("Question Explanation")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview
struct MistakesReviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MistakesReviewView(
                user: User(
                    name: "Alex",
                    avatar: "avatar-1",
                    gradeLevel: 5
                )
            )
        }
    }
} 
