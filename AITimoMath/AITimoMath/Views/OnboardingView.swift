import SwiftUI

/// Main view handling the onboarding process
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var selectedAvatar = "avatar-1"
    @State private var selectedGrade = 1
    @State private var learningGoal = 10
    @State private var showAssessment = false
    
    // Available avatar options
    private let avatarOptions = ["avatar-1", "avatar-2", "avatar-3", "avatar-4", "avatar-5", "avatar-6"]
    
    var body: some View {
        VStack {
            // Progress indicator
            HStack {
                ForEach(0..<3) { step in
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(step <= currentStep ? .blue : .gray.opacity(0.3))
                }
            }
            .padding(.top, 20)
            
            TabView(selection: $currentStep) {
                // Step 1: Welcome
                welcomeView
                    .tag(0)
                
                // Step 2: Profile setup
                profileSetupView
                    .tag(1)
                
                // Step 3: Learning goals
                learningGoalsView
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(currentStep == 2 ? "Get Started" : "Continue") {
                    if currentStep < 2 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        // Create user and complete onboarding
                        let user = User(
                            name: userName,
                            avatar: selectedAvatar,
                            gradeLevel: selectedGrade
                        )
                        // In a real app, we would save this user
                        // UserService.shared.saveUser(user)
                        isOnboardingComplete = true
                        
                        if showAssessment {
                            // Would navigate to assessment here
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentStep == 1 && userName.isEmpty)
            }
            .padding()
        }
        .padding()
    }
    
    // Welcome screen view
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Image("welcome-image")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.top, 20)
            
            Text("Welcome to TIMO Math")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("AI-powered adaptive learning to help you master math skills at your own pace.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("TIMO Math uses artificial intelligence to adapt to your learning style and provide personalized lessons.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // Profile setup view
    private var profileSetupView: some View {
        VStack(spacing: 25) {
            Text("Create Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // Avatar selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Choose your avatar")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 15) {
                    ForEach(avatarOptions, id: \.self) { avatar in
                        Image(avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .background(selectedAvatar == avatar ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selectedAvatar == avatar ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedAvatar = avatar
                            }
                    }
                }
            }
            
            // Name field
            VStack(alignment: .leading, spacing: 10) {
                Text("What's your name?")
                    .font(.headline)
                
                TextField("Enter your name", text: $userName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Grade selection
            VStack(alignment: .leading, spacing: 10) {
                Text("What grade are you in?")
                    .font(.headline)
                
                HStack {
                    ForEach(1...6, id: \.self) { grade in
                        Button(action: {
                            selectedGrade = grade
                        }) {
                            Text("\(grade)")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundColor(selectedGrade == grade ? .white : .primary)
                                .background(selectedGrade == grade ? Color.blue : Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // Learning goals view
    private var learningGoalsView: some View {
        VStack(spacing: 25) {
            Text("Set Your Learning Goals")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            Image("goals-image")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .padding(.bottom, 20)
            
            // Daily goal slider
            VStack(alignment: .leading, spacing: 10) {
                Text("How many questions per day?")
                    .font(.headline)
                
                HStack {
                    Text("5")
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { Double(learningGoal) },
                        set: { learningGoal = Int($0) }
                    ), in: 5...20, step: 1)
                    
                    Text("20")
                        .foregroundColor(.secondary)
                }
                
                Text("\(learningGoal) questions")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            // Optional skill assessment toggle
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $showAssessment) {
                    Text("Take a quick skill assessment")
                        .font(.headline)
                }
                
                if showAssessment {
                    Text("This helps us personalize your learning experience by finding the right starting difficulty for you.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
} 