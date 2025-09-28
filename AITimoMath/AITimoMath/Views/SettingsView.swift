import SwiftUI

struct SettingsView: View {
    @ObservedObject var user: User
    @AppStorage("enableAIHints") private var enableAIHints = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("isOnboarded") private var isOnboarded = true
    
    // Difficulty options mapped to User.DifficultyLevel enum
    private let difficultyOptions = [
        User.DifficultyLevel.beginner,
        User.DifficultyLevel.adaptive,
        User.DifficultyLevel.advanced
    ]
    
    var body: some View {
        Form {
            // User Profile Section
            Section(header: Text("Profile")) {
                HStack {
                    Image(user.avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(user.name)
                            .font(.headline)
                        
                        Text("Grade \(user.gradeLevel)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: EditProfileView(user: user)) {
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Learning Preferences
            Section(header: Text("Learning Preferences")) {
                // AI Hints Toggle
                Toggle(isOn: $enableAIHints) {
                    Label {
                        Text("Enable AI Hints")
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                // Difficulty Mode
                HStack {
                    Label {
                        Text("Difficulty Level")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { user.difficultyLevel },
                        set: { newValue in
                            user.difficultyLevel = newValue
                            // Trigger immediate save for important settings
                            user.saveNow()
                        }
                    )) {
                        ForEach(difficultyOptions, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Daily Goal
                HStack {
                    Label {
                        Text("Daily Goal")
                    } icon: {
                        Image(systemName: "target")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Stepper("\(user.dailyGoal) questions", value: Binding(
                        get: { user.dailyGoal },
                        set: { newValue in
                            user.dailyGoal = newValue
                            // Trigger immediate save for important settings
                            user.saveNow()
                        }
                    ), in: 3...20)
                }
            }
            
            // App Settings
            Section(header: Text("App Settings")) {
                // Notifications
                Toggle(isOn: $enableNotifications) {
                    Label {
                        Text("Notifications")
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // Dark Mode
                Toggle(isOn: $darkMode) {
                    Label {
                        Text("Dark Mode")
                    } icon: {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                    }
                }
                
                // Notification settings (only if notifications are enabled)
                if enableNotifications {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label {
                            Text("Manage Notifications")
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Support & Info
            Section(header: Text("Support & Info")) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label {
                        Text("Privacy Policy")
                    } icon: {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Label {
                        Text("Terms of Service")
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                NavigationLink(destination: AboutView()) {
                    Label {
                        Text("About App")
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Account Actions
            Section {
                Button(action: {
                    // Reset onboarding flag to show onboarding again
                    isOnboarded = false
                }) {
                    HStack {
                        Spacer()
                        
                        Text("Restart Onboarding")
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                }
                
                Button(action: {
                    // In a real app, this would log out the user
                }) {
                    HStack {
                        Spacer()
                        
                        Text("Log Out")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - EditProfileView
struct EditProfileView: View {
    @ObservedObject var user: User
    @State private var name: String
    @State private var selectedGrade: Int
    @State private var selectedAvatar: String
    
    @Environment(\.presentationMode) var presentationMode
    
    // Initialize with user's current values
    init(user: User) {
        self.user = user
        _name = State(initialValue: user.name)
        _selectedGrade = State(initialValue: user.gradeLevel)
        _selectedAvatar = State(initialValue: user.avatar)
    }
    
    // List of available avatars
    private let avatars = [
        "avatar-boy-1", "avatar-boy-2", "avatar-boy-3", "avatar-boy-4",
        "avatar-girl-1", "avatar-girl-2", "avatar-girl-3", "avatar-girl-4",
        "avatar-cat", "avatar-bear", "avatar-owl", "avatar-bunny"
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Profile Information")) {
                TextField("Name", text: $name)
                
                Picker("Grade Level", selection: $selectedGrade) {
                    ForEach(1...6, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade)
                    }
                }
            }
            
            Section(header: Text("Avatar")) {
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
                .padding(.vertical)
            }
            
            Section {
                Button(action: saveChanges) {
                    HStack {
                        Spacer()
                        Text("Save Changes")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
            }
        }
        .navigationTitle("Edit Profile")
    }
    
    private func saveChanges() {
        // Update user properties
        user.name = name
        user.gradeLevel = selectedGrade
        user.avatar = selectedAvatar
        
        // Save to Core Data
        do {
            try PersistenceController.shared.saveUser(user)
            print("User profile saved successfully")
        } catch {
            print("Error saving user profile: \(error)")
        }
        
        // Dismiss view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Placeholder Views
struct NotificationSettingsView: View {
    @AppStorage("dailyReminders") private var dailyReminders = true
    @AppStorage("weeklySummary") private var weeklySummary = true
    @AppStorage("achievementAlerts") private var achievementAlerts = true
    
    var body: some View {
        Form {
            Section(header: Text("Notification Types")) {
                Toggle("Daily Reminders", isOn: $dailyReminders)
                Toggle("Weekly Summary", isOn: $weeklySummary)
                Toggle("Achievement Alerts", isOn: $achievementAlerts)
            }
            
            Section(header: Text("About Notifications")) {
                Text("Daily Reminders")
                    .font(.headline)
                Text("Get reminded to practice math every day at your preferred time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Weekly Summary")
                    .font(.headline)
                Text("Receive a summary of your progress and achievements each week.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Achievement Alerts")
                    .font(.headline)
                Text("Get notified when you unlock new achievements or reach milestones.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Notification Settings")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is a placeholder for the privacy policy content.")
                    .font(.body)
                
                Text("In a real app, this would contain detailed information about how user data is collected, stored, and used, in compliance with GDPR, CCPA, and COPPA regulations.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is a placeholder for the terms of service content.")
                    .font(.body)
                
                Text("In a real app, this would contain detailed information about the terms of using the app, user responsibilities, and other legal information.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("app-logo") // Placeholder for app logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            
            Text("TIMO Math")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("TIMO Math is an AI-powered adaptive learning platform designed to help elementary school students improve their math skills through personalized lessons.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(
                user: User(
                    name: "Alex",
                    avatar: "avatar-boy-1",
                    gradeLevel: 5,
                    dailyGoal: 10
                )
            )
        }
    }
} 