import SwiftUI

/// A view that provides access to various test options
struct TestMenuView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("AI Model Tests")) {
                    NavigationLink(destination: AIModelTestView()) {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(.blue)
                            Text("Test AI Models")
                        }
                    }
                }
                
                Section(header: Text("Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Testing Tools")
                            .font(.headline)
                        
                        Text("These tools allow you to verify the AI model functionality in the app. You can run tests on:")
                            .font(.subheadline)
                        
                        Text("• Elo Rating Model")
                        Text("• Bayesian Knowledge Tracing Model")
                        Text("• Item Response Theory Model")
                        Text("• CoreML Service")
                        Text("• Adaptive Difficulty Engine")
                        
                        Text("Tests will validate model predictions and calculations to ensure they're working correctly.")
                            .font(.caption)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Testing Tools")
        }
    }
}

#if DEBUG
struct TestMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TestMenuView()
    }
}
#endif 