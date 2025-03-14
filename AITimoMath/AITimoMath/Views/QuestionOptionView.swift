import SwiftUI

/// A view that displays a question option which can be either text or an image
struct QuestionOptionView: View {
    /// The option to display
    let option: Question.QuestionOption
    
    /// Whether this option is selected
    let isSelected: Bool
    
    /// The option identifier (e.g., "A", "B", "C", etc.)
    let identifier: String
    
    /// Action to perform when the option is tapped
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                // Option identifier circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text(identifier)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                // Option content (text or image)
                optionContent
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// The content of the option (text or image)
    @ViewBuilder
    private var optionContent: some View {
        switch option {
        case .text(let text):
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        
        case .image(let data):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .cornerRadius(8)
            } else {
                Text("Image could not be loaded")
                    .font(.body)
                    .foregroundColor(.red)
            }
        }
    }
}

/// A view that displays a grid of question options
struct QuestionOptionsGridView: View {
    /// The options to display
    let options: [Question.QuestionOption]
    
    /// The currently selected option index
    @Binding var selectedOptionIndex: Int?
    
    /// The correct answer index (for showing feedback)
    let correctAnswerIndex: Int?
    
    /// Whether to show the correct answer
    let showCorrectAnswer: Bool
    
    /// Initializes the view with the given options
    init(
        options: [Question.QuestionOption],
        selectedOptionIndex: Binding<Int?>,
        correctAnswerIndex: Int? = nil,
        showCorrectAnswer: Bool = false
    ) {
        self.options = options
        self._selectedOptionIndex = selectedOptionIndex
        self.correctAnswerIndex = correctAnswerIndex
        self.showCorrectAnswer = showCorrectAnswer
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<options.count, id: \.self) { index in
                QuestionOptionView(
                    option: options[index],
                    isSelected: selectedOptionIndex == index,
                    identifier: String(Character(UnicodeScalar(65 + index)!)), // A, B, C, D...
                    onTap: {
                        selectedOptionIndex = index
                    }
                )
                .overlay(
                    showCorrectAnswer && correctAnswerIndex == index ?
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 3)
                            .padding(-2)
                    : nil
                )
            }
        }
    }
}

#Preview {
    VStack {
        // Preview with text options
        let textOptions: [Question.QuestionOption] = [
            .text("Paris"),
            .text("London"),
            .text("Berlin"),
            .text("Madrid")
        ]
        
        QuestionOptionsGridView(
            options: textOptions,
            selectedOptionIndex: .constant(1),
            correctAnswerIndex: 0,
            showCorrectAnswer: true
        )
        .padding()
        
        // Create an image for preview
        if let image = UIImage(systemName: "photo"), 
           let imageData = image.pngData() {
            
            // Preview with mixed options
            let mixedOptions: [Question.QuestionOption] = [
                .text("Text option 1"),
                .image(imageData),
                .text("Text option 3"),
                .image(imageData)
            ]
            
            QuestionOptionsGridView(
                options: mixedOptions,
                selectedOptionIndex: .constant(2)
            )
            .padding()
        }
    }
} 