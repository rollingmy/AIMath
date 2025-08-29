import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var name = ""
    @State private var selectedGrade = 1
    @State private var dailyGoal = 5
    @State private var selectedAvatar = "avatar-1"
    
    @Binding var isOnboarded: Bool
    @Binding var user: User
    
    // List of available avatar images
    private let avatars = ["avatar-1", "avatar-2", "avatar-3", "avatar-4", "avatar-5", "avatar-6"]
    
    var body: some View {
        VStack {
            if currentStep == 0 {
                welcomeScreen
            } else if currentStep == 1 {
                profileSetupScreen
            } else if currentStep == 2 {
                skillAssessmentScreen
            }
        }
        .animation(.easeInOut, value: currentStep)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Welcome Screen
    private var welcomeScreen: some View {
        VStack(spacing: 30) {
            Text("Welcome to TIMO Math")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Image("welcome-illustration") // Placeholder for welcome illustration
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 300)
            
            Text("Learn math with our AI-powered system that adapts to your skills")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.bottom, 20)
            
            Button(action: {
                currentStep += 1
            }) {
                Text("Start Learning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Profile Setup Screen
    private var profileSetupScreen: some View {
        VStack(spacing: 20) {
            Text("Create Your Profile")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 30)
            
            // Avatar selection
            VStack(spacing: 10) {
                Text("Choose an Avatar")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                    ForEach(avatars, id: \.self) { avatar in
                        Image(avatar)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .background(selectedAvatar == avatar ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selectedAvatar == avatar ? Color.blue : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedAvatar = avatar
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            // Name input
            VStack(alignment: .leading, spacing: 5) {
                Text("Your Name")
                    .font(.headline)
                
                TextField("Enter your name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Grade selection
            VStack(alignment: .leading, spacing: 5) {
                Text("Grade Level")
                    .font(.headline)
                
                Picker("Select Grade", selection: $selectedGrade) {
                    ForEach(1...6, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            
            // Daily goal selection
            VStack(alignment: .leading, spacing: 5) {
                Text("Daily Goal: \(dailyGoal) questions")
                    .font(.headline)
                
                Slider(value: Binding(get: {
                    Double(dailyGoal)
                }, set: {
                    dailyGoal = Int($0)
                }), in: 3...20, step: 1)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.bottom, 10)
            
            Button(action: {
                currentStep += 1
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .disabled(name.isEmpty)
        }
    }
    
    // MARK: - Skill Assessment Screen
    private var skillAssessmentScreen: some View {
        VStack(spacing: 20) {
            Text("Quick Skill Assessment")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 30)
            
            Text("Let's answer a few questions to personalize your learning")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Placeholder for the assessment questions
            Text("Assessment questions would appear here")
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: 300)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            
            Spacer()
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.bottom, 10)
            
            HStack(spacing: 15) {
                Button(action: {
                    skipAssessment()
                }) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    completeOnboarding()
                }) {
                    Text("Complete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    private func skipAssessment() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // Create the user profile
        let newUser = User(
            name: name,
            avatar: selectedAvatar,
            gradeLevel: selectedGrade,
            dailyGoal: dailyGoal
        )
        
        // Update the user binding
        user = newUser
        
        // Mark onboarding as completed
        isOnboarded = true
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            isOnboarded: .constant(false),
            user: .constant(User(name: "", avatar: "avatar-1", gradeLevel: 1))
        )
    }
} 