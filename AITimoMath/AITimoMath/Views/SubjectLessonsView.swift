import SwiftUI

struct SubjectLessonsView: View {
    let subject: String
    let iconName: String
    @ObservedObject var user: User
    
    @State private var lessons: [Lesson] = []
    @State private var isLoading = true
    
    // Sample difficulty levels for generation
    private let difficulties = [1, 2, 3, 4] // Using integers for difficulty levels
    
    // Function to load lessons for the selected subject
    private func loadLessons() {
        isLoading = true
        
        // In a real app, this would fetch lessons from a service or database
        // Here we'll create sample lessons based on the subject
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var newLessons: [Lesson] = []
            
            // Generate 5 sample lessons for this subject
            for i in 1...5 {
                let difficulty = difficulties[i % difficulties.count]
                let isCompleted = Bool.random()
                
                newLessons.append(Lesson(
                    userId: user.id,
                    subject: getSubjectEnum(from: subject)
                ))
            }
            
            self.lessons = newLessons
            self.isLoading = false
        }
    }
    
    // Helper function to convert string to Subject enum
    private func getSubjectEnum(from subjectString: String) -> Lesson.Subject {
        switch subjectString {
        case "Logical Thinking":
            return .logicalThinking
        case "Arithmetic":
            return .arithmetic
        case "Number Theory":
            return .numberTheory
        case "Geometry":
            return .geometry
        case "Combinatorics":
            return .combinatorics
        default:
            return .logicalThinking
        }
    }
    
    var body: some View {
        VStack {
            subjectHeader
            
            if isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else {
                lessonsList
            }
        }
        .navigationTitle(subject)
        .onAppear {
            loadLessons()
        }
    }
    
    // MARK: - Computed Properties
    private var subjectHeader: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 25))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(subject)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
    }
    
    private var lessonsList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(lessons) { lesson in
                    NavigationLink(destination: LessonDetailView(lesson: lesson, user: user)) {
                        lessonCard(for: lesson)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func lessonCard(for lesson: Lesson) -> some View {
        HStack {
            // Status indicator
            Circle()
                .fill(lesson.status == .completed ? Color.green : Color.orange)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(getSubjectString(from: lesson.subject))
                    .font(.headline)
                
                Text("Master key concepts in \(getSubjectString(from: lesson.subject).lowercased())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Difficulty \(lesson.difficulty)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getDifficultyColor(lesson.difficulty).opacity(0.1))
                        .foregroundColor(getDifficultyColor(lesson.difficulty))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if lesson.status == .completed {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Start Lesson")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    
    // Helper to get color based on difficulty
    private func getDifficultyColor(_ difficulty: Int) -> Color {
        switch difficulty {
        case 1:
            return .green
        case 2:
            return .blue
        case 3:
            return .orange
        case 4:
            return .purple
        default:
            return .blue
        }
    }
}

// MARK: - Preview
struct SubjectLessonsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubjectLessonsView(
                subject: "Logical Thinking",
                iconName: "brain",
                user: User(
                    name: "Alex",
                    avatar: "avatar-1",
                    gradeLevel: 5
                )
            )
        }
    }
} 