import SwiftUI

/// A view that displays a question and its options
struct QuestionView: View {
    /// The question to display
    let question: Question
    
    /// The currently selected option index
    @Binding var selectedOptionIndex: Int?
    
    /// Whether to show the correct answer
    let showCorrectAnswer: Bool
    
    /// Action to perform when the user submits their answer
    var onSubmit: (() -> Void)?
    
    /// Initializes the view with the given question
    init(
        question: Question,
        selectedOptionIndex: Binding<Int?>,
        showCorrectAnswer: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) {
        self.question = question
        self._selectedOptionIndex = selectedOptionIndex
        self.showCorrectAnswer = showCorrectAnswer
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question text
                Text(question.questionText)
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.bottom, 8)
                
                // Question image (if any)
                if let image = question.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .padding(.bottom, 8)
                }
                
                // Options
                if let options = question.options, !options.isEmpty {
                    QuestionOptionsGridView(
                        options: options,
                        selectedOptionIndex: $selectedOptionIndex,
                        correctAnswerIndex: correctAnswerIndex,
                        showCorrectAnswer: showCorrectAnswer
                    )
                }
                
                // Submit button
                if let onSubmit = onSubmit {
                    Button(action: onSubmit) {
                        Text("Submit Answer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedOptionIndex != nil ? Color.blue : Color.gray)
                            )
                    }
                    .disabled(selectedOptionIndex == nil)
                    .padding(.top, 16)
                }
                
                // Explanation (if showing correct answer)
                if showCorrectAnswer, let hint = question.hint {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(hint)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.top, 16)
                }
            }
            .padding()
        }
    }
    
    /// The index of the correct answer option
    private var correctAnswerIndex: Int? {
        guard let options = question.options else { return nil }
        
        // Find the index of the option that matches the correct answer
        for (index, option) in options.enumerated() {
            if case .text(let text) = option, text == question.correctAnswer {
                return index
            }
        }
        
        // If the correct answer is a letter (A, B, C, etc.), convert it to an index
        if question.correctAnswer.count == 1,
           let firstChar = question.correctAnswer.first,
           firstChar.isLetter,
           let asciiValue = firstChar.asciiValue {
            
            let index = Int(asciiValue) - Int(Character("A").asciiValue!)
            if index >= 0 && index < options.count {
                return index
            }
        }
        
        return nil
    }
}

#Preview {
    // Create a sample question for preview
    let subject = Lesson.Subject.arithmetic
    var question = Question(
        subject: subject,
        difficulty: 2,
        type: .multipleChoice,
        questionText: "What is the capital of France?",
        correctAnswer: "Paris"
    )
    
    // Add options
    question.addTextOption("Paris")
    question.addTextOption("London")
    question.addTextOption("Berlin")
    question.addTextOption("Madrid")
    
    // Create a preview with the sample question
    return QuestionView(
        question: question,
        selectedOptionIndex: .constant(0),
        showCorrectAnswer: true
    )
} 