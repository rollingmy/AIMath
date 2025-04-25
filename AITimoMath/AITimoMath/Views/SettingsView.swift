import SwiftUI

/// Settings and customization view
struct SettingsView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    // UI state
    @State private var enableAIHints = true
    @State private var difficultyLevel = "adaptive"
    @State private var enableNotifications = true
    @State private var studyReminders = true
    @State private var studyReminderTime = Date()
    @State private var enableDarkMode = false
    @State private var showLogoutConfirmation = false
    @State private var showResetConfirmation = false
    
    // Difficulty options
    private let difficultyOptions = ["beginner", "adaptive", "advanced"]
    
    // For backward compatibility with simple preview methods
    init(user: User) {
        self.userViewModel = UserViewModel(user: user)
        self._difficultyLevel = State(initialValue: user.difficultyLevel.rawValue)
    }
    
    // For use with the ViewModel
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
        self._difficultyLevel = State(initialValue: userViewModel.user.difficultyLevel.rawValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Learning preferences section
                Section(header: Text("Learning Preferences")) {
                    // AI hints toggle
                    Toggle("Enable AI Hints", isOn: $enableAIHints)
                        .tint(.blue)
                    
                    // Difficulty level picker
                    Picker("Difficulty Level", selection: $difficultyLevel) {
                        Text("Beginner").tag("beginner")
                        Text("Adaptive (AI)").tag("adaptive")
                        Text("Advanced").tag("advanced")
                    }
                    .pickerStyle(.menu)
                }
                
                // Notifications section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                        .tint(.blue)
                    
                    if enableNotifications {
                        Toggle("Daily Study Reminders", isOn: $studyReminders)
                            .tint(.blue)
                        
                        if studyReminders {
                            DatePicker("Reminder Time", selection: $studyReminderTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }
                
                // Appearance section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $enableDarkMode)
                        .tint(.blue)
                    
                    // Font size slider would go here
                    VStack(alignment: .leading) {
                        Text("Text Size")
                        
                        HStack {
                            Text("A")
                                .font(.caption)
                            
                            Slider(value: .constant(0.5), in: 0...1)
                                .tint(.blue)
                            
                            Text("A")
                                .font(.title)
                        }
                    }
                }
                
                // Account section
                Section(header: Text("Account")) {
                    // Profile info display
                    HStack {
                        Image(userViewModel.user.avatar)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(userViewModel.user.name)
                                .font(.headline)
                            Text("Grade \(userViewModel.user.gradeLevel)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            // Would show profile edit view
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // Parent controls (would be password protected in a real app)
                    NavigationLink(destination: Text("Parent Controls")) {
                        Label("Parent Controls", systemImage: "lock.fill")
                    }
                    
                    // Logout button
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    
                    // Reset data button
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset Learning Data")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of Use")) {
                        Text("Terms of Use")
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        Text("Help & Support")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    // Perform logout
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Reset Learning Data", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    // Reset all learning data
                }
            } message: {
                Text("This will reset all your learning progress and cannot be undone. Are you sure?")
            }
        }
    }
    
    private func saveSettings() {
        // Convert difficultyLevel string to enum
        if let difficultyEnum = User.DifficultyLevel(rawValue: difficultyLevel) {
            // In a real app, we would update the user and save changes
            // This is a placeholder for demo purposes
        }
        
        // Save notification preferences
        if enableNotifications && studyReminders {
            // Schedule notifications
            scheduleStudyReminder()
        } else {
            // Cancel existing notifications
            cancelStudyReminders()
        }
        
        // Apply dark mode if needed
        applyAppearanceSettings()
    }
    
    private func scheduleStudyReminder() {
        // This would use UNUserNotificationCenter to schedule notifications
        // For demo purposes, this is a placeholder
    }
    
    private func cancelStudyReminders() {
        // This would use UNUserNotificationCenter to cancel notifications
        // For demo purposes, this is a placeholder
    }
    
    private func applyAppearanceSettings() {
        // This would apply app-wide appearance settings
        // For demo purposes, this is a placeholder
    }
}

#Preview {
    let user = User(
        name: "Alex",
        avatar: "avatar-1",
        gradeLevel: 3
    )
    SettingsView(user: user)
} 