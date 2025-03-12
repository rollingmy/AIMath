import Foundation

/// Class responsible for file operations
class QuestionFileManager {
    /// Shared instance for app-wide use
    static let shared = QuestionFileManager()
    
    /// Read the content of a text file
    /// - Parameter url: URL of the text file
    /// - Returns: Content of the file as a string
    func readTextFile(at url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
    
    /// Read the existing timo_questions.json file
    /// - Returns: Content of the file as a string
    func readExistingJsonFile() -> String? {
        let fileManager = FileManager.default
        
        // Get the path to the Data directory
        guard let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let jsonFilePath = appSupportDirectory.appendingPathComponent("AITimoMath/Data/timo_questions.json")
        
        // Check if the file exists
        if fileManager.fileExists(atPath: jsonFilePath.path) {
            do {
                return try String(contentsOf: jsonFilePath, encoding: .utf8)
            } catch {
                print("Error reading existing JSON file: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    /// Save the JSON content to the timo_questions.json file
    /// - Parameter jsonContent: JSON content to save
    /// - Returns: Boolean indicating success or failure
    func saveJsonFile(jsonContent: String) -> Bool {
        let fileManager = FileManager.default
        
        // Get the path to the Data directory
        guard let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let dataDirectory = appSupportDirectory.appendingPathComponent("AITimoMath/Data")
        let jsonFilePath = dataDirectory.appendingPathComponent("timo_questions.json")
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: dataDirectory.path) {
            do {
                try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
                return false
            }
        }
        
        // Write the JSON content to the file
        do {
            try jsonContent.write(to: jsonFilePath, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error writing JSON file: \(error)")
            return false
        }
    }
    
    /// Save the JSON content to a custom location
    /// - Parameters:
    ///   - jsonContent: JSON content to save
    ///   - url: URL where to save the file
    /// - Returns: Boolean indicating success or failure
    func saveJsonFile(jsonContent: String, to url: URL) -> Bool {
        do {
            try jsonContent.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error writing JSON file: \(error)")
            return false
        }
    }
} 