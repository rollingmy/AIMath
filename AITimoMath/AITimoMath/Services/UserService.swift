import Foundation
import CoreData

/// Service for managing users and authentication
public class UserService {
    /// Shared instance for app-wide use
    public static let shared = UserService()
    
    /// Core Data persistence controller
    private let persistenceController = PersistenceController.shared
    
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
        
        // Fetch from Core Data if not in cache
        if let user = try persistenceController.fetchUser(id: id) {
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
        let user = User(name: name, avatar: avatar, gradeLevel: gradeLevel)
        
        // Try to validate the user
        try user.validate()
        
        // Save to Core Data
        try persistenceController.saveUser(user)
        
        // Add to cache
        userCache[user.id] = user
        
        return user
    }
    
    /// Update an existing user
    /// - Parameter user: The user to update
    /// - Returns: The updated user
    public func updateUser(_ user: User) async throws -> User {
        // Validate the user
        try user.validate()
        
        // Save to Core Data
        let updatedUser = try persistenceController.updateUser(user)
        
        // Update cache
        userCache[updatedUser.id] = updatedUser
        
        return updatedUser
    }
    
    /// Delete a user
    /// - Parameter id: The ID of the user to delete
    public func deleteUser(id: UUID) async throws {
        // Remove from cache
        userCache.removeValue(forKey: id)
        
        // Delete from Core Data
        try persistenceController.deleteUser(id: id)
    }
    
    /// Get all users
    /// - Returns: Array of all users
    public func getAllUsers() async throws -> [User] {
        // For now, return cached users since we don't have a direct "get all" method in PersistenceController
        // In a real app, you might want to add a fetchAllUsers method to PersistenceController
        return Array(userCache.values)
    }
    
    /// Get active users (those who have been active recently)
    /// - Parameter days: Number of days to consider "recent"
    /// - Returns: Array of recently active users
    public func getActiveUsers(withinDays days: Int = 7) async throws -> [User] {
        // For now, return cached users and filter by activity
        // In a real app, you might want to add a fetchActiveUsers method to PersistenceController
        let calendar = Calendar.current
        let threshold = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return userCache.values.filter { $0.lastActiveAt >= threshold }
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
    
    /// Core Data error
    case coreDataError(Error)
} 