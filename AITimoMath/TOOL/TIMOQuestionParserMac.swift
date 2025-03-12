import SwiftUI
import UniformTypeIdentifiers

@available(macOS 11.0, *)
struct TIMOQuestionParserMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentViewMac()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
    }
}

// Entry point for the application
@main
struct TIMOQuestionParserMacAppMain {
    static func main() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        
        if #available(macOS 11.0, *) {
            TIMOQuestionParserMacApp.main()
        } else {
            print("This application requires macOS 11.0 or later.")
            exit(1)
        }
    }
}

@available(macOS 11.0, *)
class QuestionParserViewModelMac: ObservableObject {
    /// Parser instance
    private let parser = QuestionParser()
    
    /// Selected text file URL
    @Published var selectedFileURL: URL?
    
    /// Content of the selected text file
    @Published var fileContent: String = ""
    
    /// Parsed questions
    @Published var parsedQuestions: [ParsedQuestion] = []
    
    /// Generated JSON content
    @Published var jsonContent: String = ""
    
    /// Status message
    @Published var statusMessage: String = "Select a text file to begin."
    
    /// Error message
    @Published var errorMessage: String = ""
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Success state
    @Published var isSuccess: Bool = false
    
    /// Select a text file
    func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                selectedFileURL = url
                loadFileContent()
            }
        }
    }
    
    /// Load the content of the selected file
    private func loadFileContent() {
        guard let url = selectedFileURL else {
            errorMessage = "No file selected."
            return
        }
        
        isLoading = true
        statusMessage = "Loading file content..."
        
        do {
            fileContent = try String(contentsOf: url, encoding: .utf8)
            statusMessage = "File loaded successfully. Ready to parse."
            parseQuestions()
        } catch {
            errorMessage = "Failed to load file content: \(error.localizedDescription)"
            statusMessage = "Error loading file."
        }
        
        isLoading = false
    }
    
    /// Parse the questions from the file content
    func parseQuestions() {
        guard !fileContent.isEmpty else {
            errorMessage = "No file content to parse."
            return
        }
        
        isLoading = true
        statusMessage = "Parsing questions..."
        
        parsedQuestions = parser.parseQuestions(from: fileContent)
        
        if parsedQuestions.isEmpty {
            errorMessage = "No questions found in the file."
            statusMessage = "Parsing failed."
        } else {
            statusMessage = "Parsed \(parsedQuestions.count) questions successfully."
            generateJson()
        }
        
        isLoading = false
    }
    
    /// Generate JSON from the parsed questions
    func generateJson() {
        guard !parsedQuestions.isEmpty else {
            errorMessage = "No questions to generate JSON from."
            return
        }
        
        isLoading = true
        statusMessage = "Generating JSON..."
        
        // Generate JSON
        jsonContent = parser.convertToJson(parsedQuestions: parsedQuestions)
        
        if jsonContent == "{}" {
            errorMessage = "Failed to generate JSON."
            statusMessage = "JSON generation failed."
        } else {
            statusMessage = "JSON generated successfully."
        }
        
        isLoading = false
    }
    
    /// Save the generated JSON to a file
    func saveJson() {
        guard !jsonContent.isEmpty else {
            errorMessage = "No JSON content to save."
            return
        }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "timo_questions.json"
        panel.allowedContentTypes = [.json]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                isLoading = true
                statusMessage = "Saving JSON..."
                
                do {
                    try jsonContent.write(to: url, atomically: true, encoding: .utf8)
                    statusMessage = "JSON saved successfully to \(url.lastPathComponent)."
                    isSuccess = true
                } catch {
                    errorMessage = "Failed to save JSON: \(error.localizedDescription)"
                    statusMessage = "JSON save failed."
                }
                
                isLoading = false
            }
        }
    }
    
    /// Reset the view model state
    func reset() {
        selectedFileURL = nil
        fileContent = ""
        parsedQuestions = []
        jsonContent = ""
        statusMessage = "Select a text file to begin."
        errorMessage = ""
        isLoading = false
        isSuccess = false
    }
}

@available(macOS 11.0, *)
struct ContentViewMac: View {
    @StateObject private var viewModel = QuestionParserViewModelMac()
    
    var body: some View {
        VStack {
            // Header
            Text("TIMO Question Parser")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Convert text files to timo_questions.json format")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            // Status and error messages
            StatusViewMac(viewModel: viewModel)
            
            // Main content
            HSplitView {
                // Left panel - File selection and content
                VStack(alignment: .leading) {
                    Text("1. Select Text File")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Button("Select File") {
                        viewModel.selectFile()
                    }
                    .padding(.bottom)
                    
                    if let url = viewModel.selectedFileURL {
                        Text("Selected file: \(url.lastPathComponent)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.bottom)
                    }
                    
                    if !viewModel.fileContent.isEmpty {
                        Text("File Content:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        ScrollView {
                            Text(viewModel.fileContent)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(minWidth: 300)
                .padding()
                
                // Right panel - Parsed questions and JSON
                VStack(alignment: .leading) {
                    if !viewModel.parsedQuestions.isEmpty {
                        Text("2. Parsed Questions (\(viewModel.parsedQuestions.count))")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        List {
                            ForEach(viewModel.parsedQuestions, id: \.id) { question in
                                VStack(alignment: .leading) {
                                    Text("Subject: \(question.subject)")
                                        .font(.headline)
                                    
                                    Text("Question \(question.questionNumber)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(question.content)
                                        .padding(.vertical, 5)
                                    
                                    if !question.options.isEmpty {
                                        Text("Options:")
                                            .font(.subheadline)
                                        
                                        ForEach(question.options.indices, id: \.self) { index in
                                            Text("\(["A", "B", "C", "D"][min(index, 3)]). \(question.options[index])")
                                                .padding(.leading)
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .frame(height: 200)
                    }
                    
                    if !viewModel.jsonContent.isEmpty {
                        Text("3. Generated JSON")
                            .font(.headline)
                            .padding(.top)
                            .padding(.bottom, 5)
                        
                        ScrollView {
                            Text(viewModel.jsonContent)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(minWidth: 400)
                .padding()
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    viewModel.reset()
                }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .padding()
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.saveJson()
                }) {
                    Label("Save JSON", systemImage: "square.and.arrow.down")
                        .padding()
                }
                .disabled(viewModel.jsonContent.isEmpty)
            }
            .padding()
        }
        .padding()
    }
}

@available(macOS 11.0, *)
struct StatusViewMac: View {
    @ObservedObject var viewModel: QuestionParserViewModelMac
    
    var body: some View {
        VStack {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(viewModel.statusMessage)
                .foregroundColor(viewModel.isSuccess ? .green : .primary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Question Parser Model
struct ParsedQuestion {
    var subject: String
    var questionNumber: String
    var content: String
    var options: [String] = []
    var correctAnswer: String = ""
    
    /// Generate a unique ID based on subject and question number
    var id: String {
        return "\(subject.lowercased().replacingOccurrences(of: " ", with: "-"))-\(questionNumber.lowercased())"
    }
}

class QuestionParser {
    /// Parse the content of a text file into an array of ParsedQuestion objects
    /// - Parameter text: The content of the text file
    /// - Returns: Array of parsed questions
    func parseQuestions(from text: String) -> [ParsedQuestion] {
        var questions: [ParsedQuestion] = []
        var currentSubject = ""
        var currentQuestion: ParsedQuestion?
        
        // Split the text into lines
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if trimmedLine.isEmpty {
                continue
            }
            
            // Check if this is a subject header
            if trimmedLine.hasPrefix("###") {
                currentSubject = trimmedLine.replacingOccurrences(of: "###", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                continue
            }
            
            // Check if this is a new question
            if trimmedLine.hasPrefix("#Q") {
                // If we were building a question, add it to our list
                if let question = currentQuestion {
                    questions.append(question)
                }
                
                // Extract question number
                let questionNumber = trimmedLine.replacingOccurrences(of: "#Q", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Create a new question
                currentQuestion = ParsedQuestion(
                    subject: currentSubject,
                    questionNumber: questionNumber,
                    content: ""
                )
                continue
            }
            
            // Check if this is an option line (A., B., C., D.)
            if let optionMatch = try? NSRegularExpression(pattern: "^[A-D]\\.", options: []).firstMatch(in: trimmedLine, options: [], range: NSRange(location: 0, length: trimmedLine.utf16.count)) {
                if optionMatch.range.location == 0 {
                    // This is an option line
                    if let option = trimmedLine.split(separator: ".").last?.trimmingCharacters(in: .whitespacesAndNewlines),
                       let optionLetter = trimmedLine.first {
                        currentQuestion?.options.append(option)
                        
                        // If this is the first option, assume it's the correct answer
                        if currentQuestion?.correctAnswer.isEmpty ?? true {
                            currentQuestion?.correctAnswer = String(optionLetter)
                        }
                        continue
                    }
                }
            }
            
            // If we reach here, this is content for the current question
            if var question = currentQuestion {
                if !question.content.isEmpty {
                    question.content += "\n"
                }
                question.content += trimmedLine
                currentQuestion = question
            }
        }
        
        // Add the last question if there is one
        if let question = currentQuestion {
            questions.append(question)
        }
        
        return questions
    }
    
    /// Convert parsed questions to the JSON format required by the app
    /// - Parameters:
    ///   - parsedQuestions: Array of parsed questions
    ///   - existingJson: Existing JSON content to merge with
    /// - Returns: JSON string in the required format
    func convertToJson(parsedQuestions: [ParsedQuestion], existingJson: String? = nil) -> String {
        var jsonQuestions: [[String: Any]] = []
        
        // If we have existing JSON, parse it first
        if let existingJson = existingJson, let data = existingJson.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let existingQuestions = json["questions"] as? [[String: Any]] {
                    jsonQuestions = existingQuestions
                }
            } catch {
                print("Error parsing existing JSON: \(error)")
            }
        }
        
        // Create a dictionary structure for the JSON
        var jsonDict: [String: Any] = [
            "version": "1.0",
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "questions": [],
            "metadata": [
                "totalQuestions": parsedQuestions.count + jsonQuestions.count,
                "subjects": Array(Set(parsedQuestions.map { formatSubject($0.subject) })).sorted(),
                "generatedBy": "TIMO Question Parser"
            ]
        ]
        
        // Convert each parsed question to a dictionary
        for question in parsedQuestions {
            let difficulty = determineDifficulty(for: question)
            let aiParameters = generateAIParameters(for: difficulty)
            let tags = generateTags(for: question)
            let timeLimit = calculateTimeLimit(for: difficulty)
            let pointsValue = calculatePointsValue(for: difficulty)
            
            let questionDict: [String: Any] = [
                "id": generateUniqueId(for: question),
                "subject": formatSubject(question.subject),
                "type": "multiple-choice",
                "difficulty": difficulty.rawValue,
                "parameters": [
                    "eloRating": aiParameters.eloRating,
                    "bkt": [
                        "pLearn": aiParameters.bkt.pLearn,
                        "pGuess": aiParameters.bkt.pGuess,
                        "pSlip": aiParameters.bkt.pSlip,
                        "pKnown": aiParameters.bkt.pKnown
                    ],
                    "irt": [
                        "discrimination": aiParameters.irt.discrimination,
                        "difficulty": aiParameters.irt.difficulty,
                        "guessing": aiParameters.irt.guessing
                    ]
                ],
                "content": [
                    "question": question.content,
                    "options": question.options,
                    "correctAnswer": question.correctAnswer,
                    "explanation": generateExplanation(for: question),
                    "imageData": ""
                ],
                "metadata": [
                    "tags": tags,
                    "timeLimit": timeLimit,
                    "pointsValue": pointsValue
                ]
            ]
            
            // Add to our questions array
            jsonQuestions.append(questionDict)
        }
        
        // Add all questions to the JSON structure
        jsonDict["questions"] = jsonQuestions
        
        // Convert to JSON string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Error creating JSON: \(error)")
        }
        
        return "{}"
    }
    
    // MARK: - Helper Methods for JSON Generation
    
    /// Difficulty levels for questions
    enum QuestionDifficulty: String {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case olympiad = "Olympiad"
    }
    
    /// AI parameters for a question
    struct AIParameters {
        let eloRating: Int
        let bkt: BKTParameters
        let irt: IRTParameters
        
        struct BKTParameters {
            let pLearn: Double
            let pGuess: Double
            let pSlip: Double
            let pKnown: Double
        }
        
        struct IRTParameters {
            let discrimination: Double
            let difficulty: Double
            let guessing: Double
        }
    }
    
    /// Determine difficulty based on question complexity
    private func determineDifficulty(_ question: ParsedQuestion) -> QuestionDifficulty {
        // Count words in the question to estimate complexity
        let wordCount = question.content.split(separator: " ").count
        
        // Check for keywords that might indicate complexity
        let complexityIndicators = ["compare", "calculate", "prove", "explain", "analyze", "find all", "solve for"]
        let hasComplexityIndicators = complexityIndicators.contains { question.content.lowercased().contains($0) }
        
        // Check if question has multiple steps or calculations
        let hasMultipleSteps = question.content.contains("\n") || question.content.contains(";") || 
                              question.content.contains("First") || question.content.contains("Then")
        
        // Check if question involves advanced concepts
        let advancedConcepts = ["equation", "fraction", "geometry", "theorem", "formula", "pattern", "sequence"]
        let hasAdvancedConcepts = advancedConcepts.contains { question.content.lowercased().contains($0) }
        
        // Determine difficulty based on these factors
        if wordCount > 50 || (hasComplexityIndicators && hasMultipleSteps && hasAdvancedConcepts) {
            return .olympiad
        } else if wordCount > 30 || (hasComplexityIndicators && (hasMultipleSteps || hasAdvancedConcepts)) {
            return .hard
        } else if wordCount > 20 || hasComplexityIndicators || hasMultipleSteps || hasAdvancedConcepts {
            return .medium
        } else {
            return .easy
        }
    }
    
    /// Generate a unique ID for the question
    private func generateUniqueId(for question: ParsedQuestion) -> String {
        // Format: subject-questionNumber (e.g., logical-1, arithmetic-2)
        let subjectPrefix = formatSubjectForId(question.subject)
        return "\(subjectPrefix)-\(question.questionNumber)"
    }
    
    /// Format subject for ID generation
    private func formatSubjectForId(_ subject: String) -> String {
        // Map subject names to the expected ID prefix format
        let subjectMap = [
            "logical thinking": "logical",
            "arithmetic": "arithmetic",
            "number theory": "number-theory",
            "geometry": "geometry",
            "combinatorics": "combinatorics"
        ]
        
        return subjectMap[subject.lowercased()] ?? subject.lowercased().replacingOccurrences(of: " ", with: "-")
    }
    
    /// Format subject to match expected values
    private func formatSubject(_ subject: String) -> String {
        // Map subject names to the expected display format in the app
        let subjectMap = [
            "logical thinking": "Logical Thinking",
            "arithmetic": "Arithmetic",
            "number theory": "Number Theory",
            "geometry": "Geometry",
            "combinatorics": "Combinatorics"
        ]
        
        return subjectMap[subject.lowercased()] ?? subject
    }
    
    /// Generate appropriate AI parameters based on difficulty with randomization
    private func generateAIParameters(for difficulty: QuestionDifficulty) -> AIParameters {
        // Add some randomization to the parameters for more natural variation
        let randomElo = { (base: Int, range: Int) -> Int in
            return base + Int.random(in: 0..<range)
        }
        
        let randomDouble = { (base: Double, range: Double) -> Double in
            return base + Double.random(in: 0..<range)
        }
        
        switch difficulty {
        case .easy:
            return AIParameters(
                eloRating: randomElo(1000, 101),  // 1000-1100
                bkt: AIParameters.BKTParameters(
                    pLearn: randomDouble(0.4, 0.1),  // 0.4-0.5
                    pGuess: randomDouble(0.2, 0.1),  // 0.2-0.3
                    pSlip: randomDouble(0.05, 0.1),  // 0.05-0.15
                    pKnown: randomDouble(0.5, 0.2)   // 0.5-0.7
                ),
                irt: AIParameters.IRTParameters(
                    discrimination: randomDouble(0.7, 0.3),  // 0.7-1.0
                    difficulty: randomDouble(-1.0, 0.4),     // -1.0 to -0.6
                    guessing: randomDouble(0.2, 0.1)         // 0.2-0.3
                )
            )
        case .medium:
            return AIParameters(
                eloRating: randomElo(1100, 201),  // 1100-1300
                bkt: AIParameters.BKTParameters(
                    pLearn: randomDouble(0.35, 0.1),  // 0.35-0.45
                    pGuess: randomDouble(0.15, 0.1),  // 0.15-0.25
                    pSlip: randomDouble(0.1, 0.1),    // 0.1-0.2
                    pKnown: randomDouble(0.4, 0.2)    // 0.4-0.6
                ),
                irt: AIParameters.IRTParameters(
                    discrimination: randomDouble(0.9, 0.3),  // 0.9-1.2
                    difficulty: randomDouble(-0.3, 0.6),     // -0.3 to 0.3
                    guessing: randomDouble(0.15, 0.1)        // 0.15-0.25
                )
            )
        case .hard:
            return AIParameters(
                eloRating: randomElo(1300, 201),  // 1300-1500
                bkt: AIParameters.BKTParameters(
                    pLearn: randomDouble(0.3, 0.1),   // 0.3-0.4
                    pGuess: randomDouble(0.1, 0.1),   // 0.1-0.2
                    pSlip: randomDouble(0.15, 0.1),   // 0.15-0.25
                    pKnown: randomDouble(0.3, 0.2)    // 0.3-0.5
                ),
                irt: AIParameters.IRTParameters(
                    discrimination: randomDouble(1.1, 0.3),  // 1.1-1.4
                    difficulty: randomDouble(0.5, 0.6),      // 0.5-1.1
                    guessing: randomDouble(0.1, 0.1)         // 0.1-0.2
                )
            )
        case .olympiad:
            return AIParameters(
                eloRating: randomElo(1500, 201),  // 1500-1700
                bkt: AIParameters.BKTParameters(
                    pLearn: randomDouble(0.25, 0.1),  // 0.25-0.35
                    pGuess: randomDouble(0.05, 0.1),  // 0.05-0.15
                    pSlip: randomDouble(0.2, 0.1),    // 0.2-0.3
                    pKnown: randomDouble(0.2, 0.2)    // 0.2-0.4
                ),
                irt: AIParameters.IRTParameters(
                    discrimination: randomDouble(1.3, 0.4),  // 1.3-1.7
                    difficulty: randomDouble(1.2, 0.6),      // 1.2-1.8
                    guessing: randomDouble(0.05, 0.1)        // 0.05-0.15
                )
            )
        }
    }
    
    /// Generate tags based on question content and subject
    private func generateTags(for question: ParsedQuestion) -> [String] {
        var tags = [question.subject.lowercased().replacingOccurrences(of: " ", with: "_")]
        
        // Add tags based on content keywords
        let content = question.content.lowercased()
        
        if content.contains("compar") {
            tags.append("comparison")
        }
        
        if content.contains("pattern") || content.contains("sequence") {
            tags.append("patterns")
        }
        
        if content.contains("shape") || content.contains("triangle") || content.contains("circle") || 
           content.contains("square") || content.contains("rectangle") {
            tags.append("shapes")
        }
        
        if content.contains("add") || content.contains("sum") || content.contains("plus") {
            tags.append("addition")
        }
        
        if content.contains("subtract") || content.contains("minus") || content.contains("difference") {
            tags.append("subtraction")
        }
        
        if content.contains("multipl") || content.contains("product") || content.contains("times") {
            tags.append("multiplication")
        }
        
        if content.contains("divide") || content.contains("quotient") {
            tags.append("division")
        }
        
        if content.contains("fraction") || content.contains("decimal") {
            tags.append("fractions")
        }
        
        if content.contains("logic") || content.contains("reason") {
            tags.append("logic")
        }
        
        if content.contains("problem") || content.contains("solve") {
            tags.append("problem_solving")
        }
        
        // Limit to 5 tags maximum
        return Array(tags.prefix(5))
    }
    
    /// Generate explanation for the question
    private func generateExplanation(for question: ParsedQuestion) -> String {
        let content = question.content.lowercased()
        let subject = question.subject.lowercased()
        
        // Base explanation template
        var explanation = "To solve this \(formatSubject(question.subject).lowercased()) problem:"
        
        // Add specific explanation based on question content and subject
        if content.contains("sequence") || content.contains("pattern") {
            explanation += "\n1. Identify the pattern in the given sequence."
            explanation += "\n2. Apply the pattern to find the next number."
            explanation += "\n3. Verify your answer by checking if it follows the established pattern."
        } else if content.contains("equation") || content.contains("solve for") {
            explanation += "\n1. Isolate the variable by performing the same operations on both sides."
            explanation += "\n2. Simplify the equation step by step."
            explanation += "\n3. Verify your solution by substituting it back into the original equation."
        } else if content.contains("area") || content.contains("perimeter") {
            explanation += "\n1. Identify the shape and its dimensions."
            explanation += "\n2. Apply the appropriate formula for the requested measurement."
            explanation += "\n3. Calculate the result using the given values."
        } else if content.contains("gcd") || content.contains("greatest common") {
            explanation += "\n1. Find all factors of both numbers."
            explanation += "\n2. Identify the common factors."
            explanation += "\n3. Select the largest common factor as the GCD."
        } else if content.contains("prime") {
            explanation += "\n1. Check if the number is divisible by any integer from 2 to its square root."
            explanation += "\n2. If no divisors are found, the number is prime."
        } else if content.contains("ways") || content.contains("arrange") || content.contains("select") {
            explanation += "\n1. Determine whether this is a permutation or combination problem."
            explanation += "\n2. Apply the appropriate formula based on the problem type."
            explanation += "\n3. Calculate the result carefully, considering all constraints."
        } else if content.contains("logic") || content.contains("statement") {
            explanation += "\n1. Analyze the given logical statements carefully."
            explanation += "\n2. Determine the relationship between the premises."
            explanation += "\n3. Draw a valid conclusion based on logical rules."
        } else {
            // Generic step-by-step approach
            explanation += "\n1. Read the problem carefully to understand what is being asked."
            explanation += "\n2. Identify the key information and relevant concepts."
            explanation += "\n3. Apply the appropriate mathematical techniques."
            explanation += "\n4. Verify your answer by checking if it makes sense in the context of the problem."
        }
        
        return explanation
    }
    
    /// Calculate time limit based on difficulty
    private func calculateTimeLimit(for difficulty: QuestionDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return 60  // 1 minute
        case .medium:
            return 90  // 1.5 minutes
        case .hard:
            return 120 // 2 minutes
        case .olympiad:
            return 180 // 3 minutes
        }
    }
    
    /// Calculate points value based on difficulty
    private func calculatePointsValue(for difficulty: QuestionDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return 1
        case .medium:
            return 2
        case .hard:
            return 3
        case .olympiad:
            return 5
        }
    }
} 