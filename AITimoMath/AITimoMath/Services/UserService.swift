import Foundation
import CloudKit

/// Service for managing users and authentication
public class UserService {
    /// Shared instance for app-wide use
    public static let shared = UserService()
    
    /// The CloudKit database for user data
    private let database = CKContainer.default().privateCloudDatabase
    
    /// Cache of loaded users
    private var userCache: [UUID: User] = [:]
    
    /// Private initializer for singleton
    private init() {}
    
    /// Get a user by ID
    /// - Parameter id: The user's ID
    /// - Returns: The user if found
    public func getUser(id: UUID) async throws -> User? {
        // Check cache first
        if let cachedUser = userCache[id] {
            return cachedUser
        }
        
        // Fetch from CloudKit if not in cache
        let predicate = NSPredicate(format: "id == %@", id.uuidString)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        
        let result = try await database.records(matching: query, resultsLimit: 1)
        
        if let matchResult = result.matchResults.first,
           let record = try? matchResult.1.get(),
           let user = User(from: record) {
            // Add to cache
            userCache[id] = user
            return user
        }
        
        return nil
    }
    
    /// Create a new user
    /// - Parameters:
    ///   - name: The user's name
    ///   - avatar: The user's avatar identifier
    ///   - gradeLevel: The user's grade level
    /// - Returns: The newly created user
    public func createUser(name: String, avatar: String, gradeLevel: Int) async throws -> User {
        // Create a new user
        var user = User(name: name, avatar: avatar, gradeLevel: gradeLevel)
        
        // Try to validate the user
        try user.validate()
        
        // Save to CloudKit
        let record = user.toRecord()
        let savedRecord = try await database.save(record)
        
        // Return the user with any server-side changes
        if let savedUser = User(from: savedRecord) {
            userCache[savedUser.id] = savedUser
            return savedUser
        } else {
            return user
        }
    }
    
    /// Update an existing user
    /// - Parameter user: The user to update
    /// - Returns: The updated user
    public func updateUser(_ user: User) async throws -> User {
        // Validate the user
        try user.validate()
        
        // Convert to CKRecord
        let record = user.toRecord()
        
        // Save to CloudKit
        let savedRecord = try await database.save(record)
        
        // Update cache
        if let savedUser = User(from: savedRecord) {
            userCache[savedUser.id] = savedUser
            return savedUser
        } else {
            userCache[user.id] = user
            return user
        }
    }
    
    /// Delete a user
    /// - Parameter id: The ID of the user to delete
    public func deleteUser(id: UUID) async throws {
        // Remove from cache
        userCache.removeValue(forKey: id)
        
        // Get the record ID
        let recordID = CKRecord.ID(recordName: "User-\(id.uuidString)")
        
        // Delete from CloudKit
        try await database.deleteRecord(withID: recordID)
    }
    
    /// Get all users
    /// - Returns: Array of all users
    public func getAllUsers() async throws -> [User] {
        let query = CKQuery(recordType: User.recordType, predicate: NSPredicate(value: true))
        
        let result = try await database.records(matching: query)
        
        var users: [User] = []
        
        for matchResult in result.matchResults {
            if let record = try? matchResult.1.get(),
               let user = User(from: record) {
                users.append(user)
                userCache[user.id] = user
            }
        }
        
        return users
    }
    
    /// Get active users (those who have been active recently)
    /// - Parameter days: Number of days to consider "recent"
    /// - Returns: Array of recently active users
    public func getActiveUsers(withinDays days: Int = 7) async throws -> [User] {
        // Calculate the date threshold
        let calendar = Calendar.current
        let threshold = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Create a predicate for users active since the threshold
        let predicate = NSPredicate(format: "lastActiveAt >= %@", threshold as NSDate)
        
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        let result = try await database.records(matching: query)
        
        var users: [User] = []
        
        for matchResult in result.matchResults {
            if let record = try? matchResult.1.get(),
               let user = User(from: record) {
                users.append(user)
                userCache[user.id] = user
            }
        }
        
        return users
    }
    
    /// Track user activity
    /// - Parameter userId: The ID of the user to track
    public func trackUserActivity(userId: UUID) async throws {
        guard var user = try await getUser(id: userId) else {
            throw UserServiceError.userNotFound
        }
        
        // Update last active timestamp
        user.trackActivity()
        
        // Save the updated user
        try await updateUser(user)
    }
    
    /// Clear the user cache
    public func clearCache() {
        userCache.removeAll()
    }
}

/// Errors that can occur in the UserService
public enum UserServiceError: Error {
    /// User not found
    case userNotFound
    
    /// Failed to create user
    case creationFailed
    
    /// Validation error
    case validationError(String)
    
    /// CloudKit error
    case cloudKitError(Error)
} 