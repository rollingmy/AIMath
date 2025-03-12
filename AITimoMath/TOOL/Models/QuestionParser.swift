import Foundation

/// Model representing a parsed question from the text file
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

/// Class responsible for parsing the text file containing TIMO questions
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
        
        // Convert parsed questions to the required JSON format
        for question in parsedQuestions {
            // Create the question object
            var questionDict: [String: Any] = [
                "id": question.id,
                "subject": question.subject,
                "type": "multiple-choice",
                "difficulty": "Medium", // Default difficulty
                "parameters": [
                    "eloRating": 1100,
                    "bkt": [
                        "pLearn": 0.4,
                        "pGuess": 0.25,
                        "pSlip": 0.1,
                        "pKnown": 0.5
                    ],
                    "irt": [
                        "discrimination": 0.8,
                        "difficulty": -0.5,
                        "guessing": 0.25
                    ]
                ],
                "content": [
                    "question": question.content,
                    "options": question.options,
                    "correctAnswer": question.correctAnswer.isEmpty ? "A" : question.correctAnswer, // Default to A if not specified
                    "explanation": "Explanation for \(question.subject) question \(question.questionNumber).",
                    "imageData": ""
                ],
                "metadata": [
                    "tags": [question.subject.lowercased()],
                    "timeLimit": 60,
                    "pointsValue": 1
                ]
            ]
            
            // Add to our questions array
            jsonQuestions.append(questionDict)
        }
        
        // Create the final JSON structure
        let jsonDict: [String: Any] = [
            "version": "1.0",
            "lastUpdated": ISO8601DateFormatter().string(from: Date()),
            "questions": jsonQuestions
        ]
        
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
} 