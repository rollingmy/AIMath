import SwiftUI
import Combine

// Create a view model class that wraps the User struct
public class UserViewModel: ObservableObject {
    // The wrapped user model
    @Published var user: User
    
    // ObservableObject publisher for SwiftUI updates
    public var objectWillChange = ObservableObjectPublisher()
    
    // Initialize with a User model
    public init(user: User) {
        self.user = user
    }
    
    // Update the user's difficulty level
    public func updateDifficultyLevel(_ newLevel: User.DifficultyLevel) {
        var updatedUser = user
        updatedUser.updateDifficultyLevel(newLevel)
        user = updatedUser
        objectWillChange.send()
    }
    
    // Add completed lesson
    public func addCompletedLesson(_ lessonId: UUID) {
        var updatedUser = user
        updatedUser.addCompletedLesson(lessonId)
        user = updatedUser
        objectWillChange.send()
    }
    
    // Update learning goal
    public func updateLearningGoal(_ newGoal: Int) throws {
        var updatedUser = user
        try updatedUser.updateLearningGoal(newGoal)
        user = updatedUser
        objectWillChange.send()
    }
    
    // Track user activity
    public func trackActivity() {
        var updatedUser = user
        updatedUser.trackActivity()
        user = updatedUser
        objectWillChange.send()
    }
}

// Extension to provide color-coded UI elements based on user data
extension UserViewModel {
    // Get color for user's grade level
    var gradeLevelColor: Color {
        switch user.gradeLevel {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        case 5: return .red
        case 6: return .pink
        default: return .gray
        }
    }
    
    // Get string representation of difficulty level
    var difficultyLevelString: String {
        switch user.difficultyLevel {
        case .beginner: return "Beginner"
        case .adaptive: return "Adaptive (AI)"
        case .advanced: return "Advanced"
        }
    }
    
    // Get color for difficulty level
    var difficultyLevelColor: Color {
        switch user.difficultyLevel {
        case .beginner: return .green
        case .adaptive: return .blue
        case .advanced: return .orange
        }
    }
    
    // Get completion percentage
    var completionPercentage: Double {
        let goal = Double(user.learningGoal)
        let completed = Double(user.completedLessons.count)
        return min(completed / goal, 1.0)
    }
}

// Helper for User profile display
struct UserProfileSummary: View {
    @ObservedObject var userViewModel: UserViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            AvatarImageView(avatarName: userViewModel.user.avatar, size: 80)
                .padding(.bottom, 5)
            
            Text(userViewModel.user.name)
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(userViewModel.gradeLevelColor)
                
                Text("Grade \(userViewModel.user.gradeLevel)")
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(userViewModel.difficultyLevelColor)
                
                Text(userViewModel.difficultyLevelString)
                    .font(.subheadline)
            }
            
            if userViewModel.user.completedLessons.count > 0 {
                VStack(spacing: 5) {
                    Text("Progress: \(Int(userViewModel.completionPercentage * 100))%")
                        .font(.caption)
                    
                    ProgressView(value: userViewModel.completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 100)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
} 