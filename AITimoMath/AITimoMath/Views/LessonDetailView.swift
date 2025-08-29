import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    @ObservedObject var user: User
    
    @State private var questions: [Question] = []
    @State private var isLoading = true
    @State private var showingQuestionView = false
    
    // In a real app, this would load questions from the timo_questions.json file
    private func loadQuestions() {
        isLoading = true
        
        // Use a QuestionLoaderService to get real questions from the JSON file
        let questionLoader = QuestionLoaderService()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.questions = questionLoader.getQuestions(
                subject: getSubjectString(from: lesson.subject),
                difficulty: "Medium",
                count: 5 // Load 5 questions for this lesson
            )
            
            self.isLoading = false
        }
    }
    
    // Helper function to convert Subject enum to string
    private func getSubjectString(from subject: Lesson.Subject) -> String {
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                lessonHeader
                lessonDescription
                Divider()
                questionPreviewSection
                skillsSection
                Spacer()
                startLessonButton
            }
            .padding()
        }
        .navigationTitle("Lesson Details")
        .onAppear {
            loadQuestions()
        }
    }
    
    // MARK: - Computed Properties
    private var lessonHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(getSubjectString(from: lesson.subject))
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Text(getSubjectString(from: lesson.subject))
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(5)
                    
                    Text("Difficulty \(lesson.difficulty)")
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(5)
                }
            }
            
            Spacer()
            
            Image(systemName: getIconName(for: lesson.subject))
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
        }
    }
    
    private var lessonDescription: some View {
        Text("Practice questions in \(getSubjectString(from: lesson.subject)) to improve your skills.")
            .font(.body)
            .padding(.top, 5)
    }
    
    private var questionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Lesson Overview")
                .font(.headline)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                questionPreviews
                
                if questions.count > 3 {
                    Text("+ \(questions.count - 3) more questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var questionPreviews: some View {
        ForEach(questions.prefix(3).indices, id: \.self) { index in
            HStack(alignment: .top) {
                Text("\(index + 1).")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .frame(width: 25, alignment: .leading)
                
                // Display a preview of the question text
                Text(questions[index].questionText.split(separator: "\n").first?.description ?? "")
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .padding(.vertical, 5)
        }
    }
    
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Skills You'll Practice")
                .font(.headline)
            
            // Random skills based on the subject
            let skills = getSkillsForSubject(lesson.subject)
            
            ForEach(skills, id: \.self) { skill in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(skill)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var startLessonButton: some View {
        Button(action: {
            showingQuestionView = true
        }) {
            Text(lesson.status == .completed ? "Review Lesson" : "Start Lesson")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding(.top, 10)
        .disabled(isLoading || questions.isEmpty)
        .sheet(isPresented: $showingQuestionView) {
            if !questions.isEmpty {
                QuestionExampleView(
                    user: user,
                    onUserUpdate: { updatedUser in
                        // Handle user update if needed
                    }
                )
            }
        }
    }
    
    // Helper to get icon name for subject
    private func getIconName(for subject: Lesson.Subject) -> String {
        switch subject {
        case .logicalThinking:
            return "brain"
        case .arithmetic:
            return "plus.slash.minus"
        case .numberTheory:
            return "number"
        case .geometry:
            return "triangle"
        case .combinatorics:
            return "die.face.5"
        }
    }
    
    // Helper to generate skills based on subject
    private func getSkillsForSubject(_ subject: Lesson.Subject) -> [String] {
        switch subject {
        case .logicalThinking:
            return ["Pattern Recognition", "Deductive Reasoning", "Logical Inference", "Critical Thinking"]
        case .arithmetic:
            return ["Addition/Subtraction", "Multiplication/Division", "Fractions", "Decimals"]
        case .numberTheory:
            return ["Prime Numbers", "Factors & Multiples", "Number Sequences", "Number Properties"]
        case .geometry:
            return ["Shape Recognition", "Area & Perimeter", "Symmetry", "Spatial Reasoning"]
        case .combinatorics:
            return ["Counting Principles", "Permutations", "Combinations", "Probability"]
        }
    }
}

// MARK: - Preview
struct LessonDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LessonDetailView(
                lesson: Lesson(
                    userId: UUID(),
                    subject: .logicalThinking
                ),
                user: User(
                    name: "Alex",
                    avatar: "avatar-1",
                    gradeLevel: 5
                )
            )
        }
    }
} 