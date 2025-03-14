import SwiftUI

/// A view that demonstrates the use of image options in questions
struct QuestionExampleView: View {
    @State private var selectedOptionIndex: Int?
    @State private var showingAnswer = false
    
    var body: some View {
        VStack {
            Text("Question Example")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            QuestionView(
                question: sampleQuestionWithImageOptions,
                selectedOptionIndex: $selectedOptionIndex,
                showCorrectAnswer: showingAnswer,
                onSubmit: {
                    withAnimation {
                        showingAnswer = true
                    }
                }
            )
            
            if showingAnswer {
                Button("Try Another Question") {
                    withAnimation {
                        selectedOptionIndex = nil
                        showingAnswer = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding()
    }
    
    /// Sample question with image options
    private var sampleQuestionWithImageOptions: Question {
        var question = Question(
            subject: .geometry,
            difficulty: 2,
            type: .multipleChoice,
            questionText: "Which of these shapes has the largest area?",
            correctAnswer: "B"
        )
        
        // Create sample images for options
        if let circleImage = UIImage(systemName: "circle.fill"),
           let squareImage = UIImage(systemName: "square.fill"),
           let triangleImage = UIImage(systemName: "triangle.fill"),
           let hexagonImage = UIImage(systemName: "hexagon.fill") {
            
            // Add image options
            question.addImageOption(circleImage)
            question.addImageOption(squareImage)
            question.addImageOption(triangleImage)
            question.addImageOption(hexagonImage)
        }
        
        // Set hint
        question.hint = "The square has the largest area among the options when all shapes have the same width."
        
        return question
    }
    
    /// Sample question with mixed text and image options
    private var sampleQuestionWithMixedOptions: Question {
        var question = Question(
            subject: .numberTheory,
            difficulty: 3,
            type: .multipleChoice,
            questionText: "Which of these represents the Pythagorean theorem?",
            correctAnswer: "A"
        )
        
        // Add text option
        question.addTextOption("a² + b² = c²")
        
        // Create sample images for other options
        if let image1 = UIImage(systemName: "function"),
           let image2 = UIImage(systemName: "sum"),
           let image3 = UIImage(systemName: "divide") {
            
            // Add image options
            question.addImageOption(image1)
            question.addImageOption(image2)
            question.addImageOption(image3)
        }
        
        // Set hint
        question.hint = "The Pythagorean theorem states that in a right triangle, the square of the length of the hypotenuse equals the sum of squares of the other two sides."
        
        return question
    }
}

#Preview {
    QuestionExampleView()
} 