#!/usr/bin/swift

import Foundation

// MARK: - Data Structures

struct ParsedQuestion {
    let subject: String
    let questionNumber: Int
    let content: String
    let options: [String]
    let correctAnswer: String
}

enum QuestionDifficulty: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case olympiad = "Olympiad"
}

struct AIParameters {
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
    
    let eloRating: Int
    let bkt: BKTParameters
    let irt: IRTParameters
}

// MARK: - Question Parser

class QuestionParser {
    private var currentSubject = ""
    private var questions: [ParsedQuestion] = []
    
    // MARK: - Parsing Methods
    
    func parseQuestionsFromFile(at path: String) -> [ParsedQuestion] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Error: Could not read file at \(path)")
            return []
        }
        
        return parseQuestions(from: content)
    }
    
    func parseQuestions(from content: String) -> [ParsedQuestion] {
        questions = []
        currentSubject = ""
        
        var currentQuestion = ""
        var currentOptions: [String] = []
        var currentQuestionNumber = 0
        var parsingOptions = false
        var correctAnswer = ""
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            // Check if this is a subject header
            if trimmedLine.hasSuffix(":") && !trimmedLine.contains(".") {
                currentSubject = String(trimmedLine.dropLast())
                continue
            }
            
            // Check if this is a new question
            if let questionMatch = trimmedLine.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                // Save previous question if exists
                if !currentQuestion.isEmpty && !currentOptions.isEmpty {
                    let parsedQuestion = ParsedQuestion(
                        subject: currentSubject,
                        questionNumber: currentQuestionNumber,
                        content: currentQuestion,
                        options: currentOptions,
                        correctAnswer: correctAnswer
                    )
                    questions.append(parsedQuestion)
                }
                
                // Start new question
                let questionNumberString = trimmedLine[questionMatch.lowerBound..<questionMatch.upperBound]
                    .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
                currentQuestionNumber = Int(questionNumberString) ?? 0
                
                let questionContent = trimmedLine[questionMatch.upperBound...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                currentQuestion = String(questionContent)
                currentOptions = []
                parsingOptions = false
                correctAnswer = ""
                continue
            }
            
            // Check if this is an option
            if let optionMatch = trimmedLine.range(of: #"^[A-D]\)\s"#, options: .regularExpression) {
                parsingOptions = true
                let option = trimmedLine[optionMatch.upperBound...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let optionLetter = trimmedLine[..<optionMatch.upperBound]
                    .trimmingCharacters(in: CharacterSet(charactersIn: ") "))
                currentOptions.append(String(option))
                
                // If this is marked as correct answer
                if trimmedLine.contains("*") {
                    correctAnswer = String(optionLetter)
                }
                continue
            }
            
            // If we're not parsing options, add to question content
            if !parsingOptions {
                currentQuestion += " " + trimmedLine
            }
        }
        
        // Add the last question
        if !currentQuestion.isEmpty && !currentOptions.isEmpty {
            let parsedQuestion = ParsedQuestion(
                subject: currentSubject,
                questionNumber: currentQuestionNumber,
                content: currentQuestion,
                options: currentOptions,
                correctAnswer: correctAnswer
            )
            questions.append(parsedQuestion)
        }
        
        return questions
    }
    
    // MARK: - Difficulty Determination
    
    func determineDifficulty(for question: ParsedQuestion) -> QuestionDifficulty {
        let content = question.content.lowercased()
        var complexityScore = 0
        
        // 1. Word count - longer questions tend to be more complex
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        if wordCount > 50 {
            complexityScore += 3
        } else if wordCount > 30 {
            complexityScore += 2
        } else if wordCount > 15 {
            complexityScore += 1
        }
        
        // 2. Check for complexity indicators
        let complexityIndicators = [
            "prove": 3,
            "theorem": 3,
            "derive": 3,
            "complex": 2,
            "analyze": 2,
            "compare": 1,
            "calculate": 1,
            "find": 0,
            "what is": 0
        ]
        
        for (indicator, score) in complexityIndicators {
            if content.contains(indicator) {
                complexityScore += score
                break
            }
        }
        
        // 3. Check for multiple steps required
        if content.contains("first") && (content.contains("then") || content.contains("next")) {
            complexityScore += 2
        }
        
        // 4. Check for advanced concepts
        let advancedConcepts = [
            "equation": 1,
            "function": 1,
            "geometry": 1,
            "probability": 2,
            "combinatorics": 2,
            "algebra": 1,
            "calculus": 3,
            "proof": 3,
            "theorem": 3
        ]
        
        for (concept, score) in advancedConcepts {
            if content.contains(concept) {
                complexityScore += score
            }
        }
        
        // 5. Subject-specific adjustments
        switch question.subject.lowercased() {
        case "number theory":
            complexityScore += 1
        case "combinatorics":
            complexityScore += 1
        case "olympiad":
            complexityScore += 2
        default:
            break
        }
        
        // Determine difficulty based on complexity score
        if complexityScore >= 7 {
            return .olympiad
        } else if complexityScore >= 4 {
            return .hard
        } else if complexityScore >= 2 {
            return .medium
        } else {
            return .easy
        }
    }
    
    // MARK: - AI Parameter Generation
    
    func generateAIParameters(for difficulty: QuestionDifficulty) -> AIParameters {
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
    
    // MARK: - Helper Methods
    
    func generateTags(for question: ParsedQuestion) -> [String] {
        let content = question.content.lowercased()
        var tags = Set<String>()
        
        // Add subject as a tag
        tags.insert(formatSubject(question.subject).lowercased())
        
        // Add difficulty as a tag
        let difficulty = determineDifficulty(for: question)
        tags.insert(difficulty.rawValue.lowercased())
        
        // Check for common mathematical concepts
        let conceptMap = [
            "equation": "equations",
            "fraction": "fractions",
            "decimal": "decimals",
            "percent": "percentages",
            "angle": "angles",
            "triangle": "triangles",
            "circle": "circles",
            "square": "squares",
            "rectangle": "rectangles",
            "polygon": "polygons",
            "sequence": "sequences",
            "pattern": "patterns",
            "prime": "prime numbers",
            "factor": "factorization",
            "multiple": "multiples",
            "divisor": "divisors",
            "gcd": "greatest common divisor",
            "lcm": "least common multiple",
            "probability": "probability",
            "statistic": "statistics",
            "mean": "mean",
            "median": "median",
            "mode": "mode",
            "range": "range",
            "function": "functions",
            "graph": "graphs",
            "coordinate": "coordinates",
            "area": "area",
            "perimeter": "perimeter",
            "volume": "volume",
            "surface area": "surface area",
            "logic": "logic",
            "proof": "proofs",
            "theorem": "theorems"
        ]
        
        for (keyword, tag) in conceptMap {
            if content.contains(keyword) {
                tags.insert(tag)
            }
        }
        
        return Array(tags.prefix(5))
    }
    
    func calculateTimeLimit(for difficulty: QuestionDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return 60
        case .medium:
            return 90
        case .hard:
            return 120
        case .olympiad:
            return 180
        }
    }
    
    func calculatePointsValue(for difficulty: QuestionDifficulty) -> Int {
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
    
    // MARK: - ID and Subject Formatting
    
    func generateUniqueId(for question: ParsedQuestion) -> String {
        // Format: subject-questionNumber (e.g., logical-1, arithmetic-2)
        let subjectPrefix = formatSubjectForId(question.subject)
        return "\(subjectPrefix)-\(question.questionNumber)"
    }
    
    func formatSubjectForId(_ subject: String) -> String {
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
    
    func formatSubject(_ subject: String) -> String {
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
    
    // MARK: - Explanation Generation
    
    func generateExplanation(for question: ParsedQuestion) -> String {
        let content = question.content.lowercased()
        
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
    
    // MARK: - JSON Conversion
    
    func convertToJSON(parsedQuestions: [ParsedQuestion]) -> Data? {
        // Create a dictionary structure for the JSON
        var jsonDict: [String: Any] = [
            "version": "1.0",
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "questions": [],
            "metadata": [
                "totalQuestions": parsedQuestions.count,
                "subjects": Array(Set(parsedQuestions.map { formatSubject($0.subject) })).sorted(),
                "generatedBy": "TIMO Question Parser Test"
            ]
        ]
        
        // Convert each parsed question to a dictionary
        var questionsArray: [[String: Any]] = []
        
        for question in parsedQuestions {
            let difficulty = determineDifficulty(for: question)
            let aiParameters = generateAIParameters(for: difficulty)
            let tags = generateTags(for: question)
            let timeLimit = calculateTimeLimit(for: difficulty)
            let pointsValue = calculatePointsValue(for: difficulty)
            
            var questionDict: [String: Any] = [
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
            
            questionsArray.append(questionDict)
        }
        
        jsonDict["questions"] = questionsArray
        
        // Convert to JSON data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [.prettyPrinted])
            return jsonData
        } catch {
            print("Error converting to JSON: \(error)")
            return nil
        }
    }
}

// MARK: - Main Execution

// Parse the complex sample file
let parser = QuestionParser()
let filePath = "complex_sample.txt"
let questions = parser.parseQuestionsFromFile(at: filePath)

print("Parsed \(questions.count) questions from \(filePath)")

// Process each question and display information
for question in questions {
    let difficulty = parser.determineDifficulty(for: question)
    let aiParams = parser.generateAIParameters(for: difficulty)
    let tags = parser.generateTags(for: question)
    let id = parser.generateUniqueId(for: question)
    
    print("\nQuestion ID: \(id)")
    print("Subject: \(parser.formatSubject(question.subject))")
    print("Content: \(question.content.prefix(50))...")
    print("Difficulty: \(difficulty.rawValue)")
    print("Elo Rating: \(aiParams.eloRating)")
    print("IRT Difficulty: \(aiParams.irt.difficulty)")
    print("Tags: \(tags.joined(separator: ", "))")
}

// Generate JSON and save to file
if let jsonData = parser.convertToJSON(parsedQuestions: questions) {
    let outputPath = "complex_output.json"
    do {
        try jsonData.write(to: URL(fileURLWithPath: outputPath))
        print("\nJSON output saved to \(outputPath)")
    } catch {
        print("Error writing JSON to file: \(error)")
    }
    
    // Print a sample of the JSON
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        let previewLength = min(500, jsonString.count)
        print("\nJSON Preview (first \(previewLength) characters):")
        print(jsonString.prefix(previewLength))
        print("...")
    }
} 