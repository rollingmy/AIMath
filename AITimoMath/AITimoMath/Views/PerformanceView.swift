import SwiftUI

/// View displaying the user's performance analytics
struct PerformanceView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Mock data for UI development
    private let subjectAccuracy: [String: Double] = [
        "Logical Thinking": 0.72,
        "Arithmetic": 0.85,
        "Number Theory": 0.64,
        "Geometry": 0.56,
        "Combinatorics": 0.43
    ]
    
    private let weeklyProgressData: [Double] = [0.65, 0.7, 0.72, 0.68, 0.75, 0.78, 0.76]
    
    // Mock weakness areas
    private let weaknessAreas = [
        "Fraction operations",
        "Geometric transformations",
        "Multi-step word problems",
        "Advanced pattern recognition"
    ]

    // For backward compatibility with simple preview methods
    init(user: User) {
        self.userViewModel = UserViewModel(user: user)
    }
    
    // For use with the ViewModel
    init(userViewModel: UserViewModel) {
        self.userViewModel = userViewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Performance overview section
                    overallPerformanceSection
                    
                    // Weekly progress chart section
                    weeklyProgressSection
                    
                    // Subject breakdown section
                    subjectBreakdownSection
                    
                    // Weakness analysis section
                    weaknessAnalysisSection
                    
                    // Action buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("Performance Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    // Overall performance metrics
    private var overallPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Overall Performance")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Accuracy metric
                performanceMetricView(
                    title: "Accuracy",
                    value: "76%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // Response time metric
                performanceMetricView(
                    title: "Avg. Response",
                    value: "32s",
                    icon: "clock.fill",
                    color: .blue
                )
                
                // Lessons completed
                performanceMetricView(
                    title: "Lessons",
                    value: "\(userViewModel.user.completedLessons.count)",
                    icon: "book.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // Helper for consistent metric display
    private func performanceMetricView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Weekly progress chart
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Progress")
                .font(.headline)
            
            // Line graph for weekly progress
            HStack(alignment: .bottom, spacing: 8) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 15) {
                    Text("100%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("75%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("50%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("25%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("0%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 35)
                
                // Line chart
                HStack(alignment: .bottom, spacing: 25) {
                    ForEach(0..<weeklyProgressData.count, id: \.self) { index in
                        VStack(spacing: 5) {
                            // Data point
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 12, height: 12)
                                )
                                .offset(y: -CGFloat(weeklyProgressData[index] * 120))
                            
                            // Day label
                            Text(dayAbbreviation(for: index))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 130, alignment: .bottom)
                    }
                }
                .overlay(
                    // Connect data points with lines
                    ZStack {
                        ForEach(0..<(weeklyProgressData.count - 1), id: \.self) { index in
                            Path { path in
                                path.move(to: CGPoint(x: CGFloat(index) * 33 + 4, y: 120 - CGFloat(weeklyProgressData[index] * 120)))
                                path.addLine(to: CGPoint(x: CGFloat(index + 1) * 33 + 4, y: 120 - CGFloat(weeklyProgressData[index + 1] * 120)))
                            }
                            .stroke(Color.blue, lineWidth: 2)
                        }
                    }
                )
                .padding(.leading, 10)
            }
            .padding(.vertical, 10)
            .frame(height: 160)
            .overlay(
                // Horizontal grid lines
                VStack(spacing: 30) {
                    ForEach(0..<5) { _ in
                        Divider()
                    }
                }
                .offset(y: -15)
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // Subject-wise breakdown
    private var subjectBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Subject Breakdown")
                .font(.headline)
            
            ForEach(subjectAccuracy.sorted(by: { $0.value > $1.value }), id: \.key) { subject, accuracy in
                HStack {
                    Text(subject)
                        .font(.subheadline)
                        .frame(width: 140, alignment: .leading)
                    
                    // Progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(subjectColor(subject))
                            .frame(width: CGFloat(accuracy) * 200, height: 8)
                            .cornerRadius(4)
                    }
                    
                    Text("\(Int(accuracy * 100))%")
                        .font(.subheadline)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // AI-detected weakness areas
    private var weaknessAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Areas for Improvement")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(weaknessAreas, id: \.self) { area in
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .frame(width: 20)
                        
                        Text(area)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Text("These areas have been identified by our AI analysis based on your recent performance.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    // Action buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            Button(action: {
                // Start improvement session
            }) {
                Text("Start Improvement Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            
            Button(action: {
                // Export or share progress
            }) {
                Text("Share Progress Report")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(15)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Helper for day abbreviation
    private func dayAbbreviation(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let today = Calendar.current.component(.weekday, from: Date()) - 1
        let wrappedIndex = (today + index) % 7
        return days[wrappedIndex]
    }
    
    // Helper for subject color
    private func subjectColor(_ subject: String) -> Color {
        switch subject {
        case "Logical Thinking":
            return .purple
        case "Arithmetic":
            return .blue
        case "Number Theory":
            return .green
        case "Geometry":
            return .orange
        case "Combinatorics":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    let user = User(
        name: "Alex",
        avatar: "avatar-1",
        gradeLevel: 3
    )
    PerformanceView(user: user)
} 