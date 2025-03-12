import Foundation
import SwiftUI

/// View model for the question parser UI
class QuestionParserViewModel: ObservableObject {
    /// Parser instance
    private let parser = QuestionParser()
    
    /// File manager instance
    private let fileManager = QuestionFileManager.shared
    
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
    /// - Parameter url: URL of the selected file
    func selectFile(url: URL) {
        selectedFileURL = url
        loadFileContent()
    }
    
    /// Load the content of the selected file
    private func loadFileContent() {
        guard let url = selectedFileURL else {
            errorMessage = "No file selected."
            return
        }
        
        isLoading = true
        statusMessage = "Loading file content..."
        
        if let content = fileManager.readTextFile(at: url) {
            fileContent = content
            statusMessage = "File loaded successfully. Ready to parse."
            parseQuestions()
        } else {
            errorMessage = "Failed to load file content."
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
        
        // Read existing JSON file if available
        let existingJson = fileManager.readExistingJsonFile()
        
        // Generate JSON
        jsonContent = parser.convertToJson(parsedQuestions: parsedQuestions, existingJson: existingJson)
        
        if jsonContent == "{}" {
            errorMessage = "Failed to generate JSON."
            statusMessage = "JSON generation failed."
        } else {
            statusMessage = "JSON generated successfully."
        }
        
        isLoading = false
    }
    
    /// Save the generated JSON to the timo_questions.json file
    func saveJson() {
        guard !jsonContent.isEmpty else {
            errorMessage = "No JSON content to save."
            return
        }
        
        isLoading = true
        statusMessage = "Saving JSON..."
        
        if fileManager.saveJsonFile(jsonContent: jsonContent) {
            statusMessage = "JSON saved successfully to timo_questions.json."
            isSuccess = true
        } else {
            errorMessage = "Failed to save JSON."
            statusMessage = "JSON save failed."
        }
        
        isLoading = false
    }
    
    /// Save the generated JSON to a custom location
    /// - Parameter url: URL where to save the file
    func saveJson(to url: URL) {
        guard !jsonContent.isEmpty else {
            errorMessage = "No JSON content to save."
            return
        }
        
        isLoading = true
        statusMessage = "Saving JSON..."
        
        if fileManager.saveJsonFile(jsonContent: jsonContent, to: url) {
            statusMessage = "JSON saved successfully to \(url.lastPathComponent)."
            isSuccess = true
        } else {
            errorMessage = "Failed to save JSON."
            statusMessage = "JSON save failed."
        }
        
        isLoading = false
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