import Foundation

/// Alert message model that conforms to Identifiable for use with SwiftUI's .alert(item:) modifier
struct AlertMessage: Identifiable {
    /// Unique identifier
    let id = UUID()
    
    /// Message text to display
    let message: String
    
    /// Optional title for the alert
    let title: String
    
    /// Initialize with a message and optional title
    init(_ message: String, title: String = "Error") {
        self.message = message
        self.title = title
    }
} 