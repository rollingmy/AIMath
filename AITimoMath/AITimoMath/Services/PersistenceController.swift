import Foundation
import CloudKit
import CoreData

/// Handles data persistence and CloudKit synchronization for the app
class PersistenceController {
    /// Shared instance for app-wide use
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        Task {
            let sampleUser = User(
                name: "Sample Student",
                avatar: "student_avatar",
                gradeLevel: 3
            )
            do {
                _ = try await controller.saveUser(sampleUser)
            } catch {
                print("Failed to save sample user for preview: \(error.localizedDescription)")
            }
        }
        
        return controller
    }()
    
    /// CloudKit container for data storage
    private let container: CKContainer
    
    /// Private database for user data
    private let privateDatabase: CKDatabase
    
    /// Core Data container
    let persistentContainer: NSPersistentCloudKitContainer
    
    /// Initialize with default CloudKit container and Core Data setup
    private init(inMemory: Bool = false) {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        
        // Initialize Core Data container
        persistentContainer = NSPersistentCloudKitContainer(name: "AITimoMath")
        
        if inMemory {
            // Use in-memory store for previews
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure Core Data stack
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        
        // Enable CloudKit sync
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure view context for better preview performance
        if inMemory {
            persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            persistentContainer.viewContext.undoManager = nil
            persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
        }
    }
    
    /// Returns the managed object context for the main thread
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// Save user data to CloudKit
    /// - Parameter user: The user to save
    /// - Returns: A boolean indicating success
    func saveUser(_ user: User) async throws -> Bool {
        do {
            try user.validate()
            let record = user.toRecord()
            _ = try await privateDatabase.save(record)
            return true
        } catch {
            print("Error saving user: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Fetch user by ID
    /// - Parameter id: The UUID of the user to fetch
    /// - Returns: Optional User if found
    func fetchUser(id: UUID) async throws -> User? {
        let predicate = NSPredicate(format: "id == %@", id.uuidString)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query)
            for result in results {
                if let record = try? result.1.get() {
                    return User(from: record)
                }
            }
            return nil
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update existing user
    /// - Parameter user: The user to update
    /// - Returns: Updated user if successful
    func updateUser(_ user: User) async throws -> User {
        do {
            try user.validate()
            let record = user.toRecord()
            let updatedRecord = try await privateDatabase.save(record)
            guard let updatedUser = User(from: updatedRecord) else {
                throw PersistenceError.updateFailed
            }
            return updatedUser
        } catch {
            print("Error updating user: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Delete user by ID
    /// - Parameter id: The UUID of the user to delete
    func deleteUser(id: UUID) async throws {
        let predicate = NSPredicate(format: "id == %@", id.uuidString)
        let query = CKQuery(recordType: User.recordType, predicate: predicate)
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query)
            for result in results {
                if let record = try? result.1.get() {
                    try await privateDatabase.deleteRecord(withID: record.recordID)
                    return
                }
            }
        } catch {
            print("Error deleting user: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Preview Helpers
extension PersistenceController {
    /// Creates a testing background context
    func createBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    /// Saves context if there are changes
    func save() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Error Handling
extension PersistenceController {
    enum PersistenceError: Error {
        case updateFailed
        case deleteFailed
        case fetchFailed
        case invalidData
    }
} 