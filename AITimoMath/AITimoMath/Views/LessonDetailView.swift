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
            // Use selected lesson subject; show lesson.difficulty badge but preview can pull nearest difficulties
            // Keep preview aligned to subject only
            self.questions = questionLoader.getQuestions(
                subject: getSubjectString(from: lesson.subject),
                difficulty: nil,
                count: min(user.dailyGoal, 10)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(getEngagingDescription(for: lesson.subject))
                .font(.body)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Estimated time: \(getEstimatedTime()) minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.blue)
                Text("\(questions.count) questions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(width: 25, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Display a preview of the question text (first line only)
                        Text(getQuestionPreview(questions[index].questionText))
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundColor(.primary)
                        
                        // Show question type and difficulty
                        HStack {
                            Text(questions[index].type == .multipleChoice ? "Multiple Choice" : "Open Ended")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                            
                            Text("Level \(questions[index].difficulty)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
    }
    
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Skills You'll Practice")
                .font(.headline)
            
            // Get detailed skills based on the subject
            let skills = getDetailedSkillsForSubject(lesson.subject)
            
            ForEach(skills, id: \.name) { skill in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: skill.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(skill.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(skill.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 24)
                }
                .padding(.vertical, 4)
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
                    subject: lesson.subject,
                    difficulty: lesson.difficulty,
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
    
    // Helper to generate engaging descriptions based on subject
    private func getEngagingDescription(for subject: Lesson.Subject) -> String {
        switch subject {
        case .logicalThinking:
            return "Develop your critical thinking skills with engaging logic puzzles and pattern recognition challenges. Perfect for building problem-solving abilities!"
        case .arithmetic:
            return "Master fundamental math operations with interactive exercises. Build confidence in addition, subtraction, multiplication, and division."
        case .numberTheory:
            return "Explore the fascinating world of numbers! Learn about prime numbers, factors, sequences, and discover the hidden patterns in mathematics."
        case .geometry:
            return "Discover shapes, angles, and spatial relationships through visual learning. Develop your geometric intuition and problem-solving skills."
        case .combinatorics:
            return "Learn counting principles and probability through fun, real-world scenarios. Perfect for developing analytical thinking!"
        }
    }
    
    // Helper to get estimated time based on question count and difficulty
    private func getEstimatedTime() -> Int {
        let baseTime = questions.count * 2 // 2 minutes per question
        let difficultyMultiplier = Double(lesson.difficulty) * 0.5 // Add 0.5 minutes per difficulty level
        return Int(Double(baseTime) + difficultyMultiplier)
    }
    
    // Helper to get question preview (first line only)
    private func getQuestionPreview(_ questionText: String) -> String {
        let lines = questionText.components(separatedBy: "\n")
        let firstLine = lines.first ?? questionText
        
        // Remove Vietnamese text if present (text after \n)
        if firstLine.contains("\n") {
            let parts = firstLine.components(separatedBy: "\n")
            return parts.first ?? firstLine
        }
        
        return firstLine
    }
    
    // Helper to generate detailed skills based on subject
    private func getDetailedSkillsForSubject(_ subject: Lesson.Subject) -> [SkillInfo] {
        switch subject {
        case .logicalThinking:
            return [
                SkillInfo(name: "Pattern Recognition", description: "Identify and extend number and shape patterns", icon: "waveform.path.ecg"),
                SkillInfo(name: "Deductive Reasoning", description: "Draw logical conclusions from given information", icon: "brain.head.profile"),
                SkillInfo(name: "Critical Thinking", description: "Analyze problems and find creative solutions", icon: "lightbulb.fill"),
                SkillInfo(name: "Logical Inference", description: "Make educated guesses based on evidence", icon: "arrow.triangle.branch")
            ]
        case .arithmetic:
            return [
                SkillInfo(name: "Basic Operations", description: "Master addition, subtraction, multiplication, and division", icon: "plus.slash.minus"),
                SkillInfo(name: "Number Sense", description: "Understand number relationships and properties", icon: "number.circle"),
                SkillInfo(name: "Mental Math", description: "Perform calculations quickly and accurately", icon: "brain"),
                SkillInfo(name: "Problem Solving", description: "Apply arithmetic to real-world situations", icon: "puzzlepiece.fill")
            ]
        case .numberTheory:
            return [
                SkillInfo(name: "Prime Numbers", description: "Identify and work with prime and composite numbers", icon: "star.fill"),
                SkillInfo(name: "Factors & Multiples", description: "Find factors, multiples, and common divisors", icon: "divide.circle"),
                SkillInfo(name: "Number Sequences", description: "Recognize and continue number patterns", icon: "arrow.right.circle"),
                SkillInfo(name: "Number Properties", description: "Understand odd, even, and special number properties", icon: "number.square")
            ]
        case .geometry:
            return [
                SkillInfo(name: "Shape Recognition", description: "Identify and classify 2D and 3D shapes", icon: "triangle.fill"),
                SkillInfo(name: "Area & Perimeter", description: "Calculate measurements of shapes and spaces", icon: "ruler"),
                SkillInfo(name: "Spatial Reasoning", description: "Visualize and manipulate objects in space", icon: "cube.fill"),
                SkillInfo(name: "Symmetry", description: "Recognize and create symmetrical patterns", icon: "mirror")
            ]
        case .combinatorics:
            return [
                SkillInfo(name: "Counting Principles", description: "Use systematic methods to count possibilities", icon: "list.number"),
                SkillInfo(name: "Permutations", description: "Arrange objects in different orders", icon: "arrow.2.squarepath"),
                SkillInfo(name: "Combinations", description: "Select groups without considering order", icon: "person.3.fill"),
                SkillInfo(name: "Probability", description: "Calculate chances and likelihood of events", icon: "percent")
            ]
        }
    }
    
    // Helper to generate skills based on subject (legacy)
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

// MARK: - Supporting Structures
struct SkillInfo {
    let name: String
    let description: String
    let icon: String
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