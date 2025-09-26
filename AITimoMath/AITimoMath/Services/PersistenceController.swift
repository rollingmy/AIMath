import Foundation
import CoreData

/// Handles data persistence using Core Data for the app
class PersistenceController {
    /// Shared instance for app-wide use
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        let sampleUser = User(
            name: "Sample Student",
            avatar: "student_avatar",
            gradeLevel: 3
        )
        try? controller.saveUser(sampleUser)
        
        return controller
    }()
    
    /// Core Data container
    let persistentContainer: NSPersistentContainer
    
    /// Initialize with Core Data setup
    private init(inMemory: Bool = false) {
        // Initialize Core Data container
        persistentContainer = NSPersistentContainer(name: "AITimoMath")
        
        if inMemory {
            // Use in-memory store for previews
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure Core Data stack with migration handling
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data store failed to load: \(error.localizedDescription)")
                
                // Check if this is a migration error (NSCocoaErrorDomain 134140)
                if let nsError = error as NSError?,
                   nsError.domain == "NSCocoaErrorDomain" && nsError.code == 134140 {
                    print("Migration error detected. Attempting to delete and recreate store...")
                    
                    // Delete the existing store and recreate
                    self.deleteExistingStore()
                    
                    // Try to load again
                    self.persistentContainer.loadPersistentStores { description, error in
                        if let error = error {
                            fatalError("Core Data store failed to load after migration: \(error.localizedDescription)")
                        } else {
                            print("Core Data store successfully recreated after migration")
                        }
                    }
                } else {
                    fatalError("Core Data store failed to load: \(error.localizedDescription)")
                }
            }
        }
        
        // Configure view context
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
    
    /// Delete existing Core Data store files to handle migration issues
    private func deleteExistingStore() {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            print("No store URL found")
            return
        }
        
        let storeDirectory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.lastPathComponent
        
        // Delete all related files
        let fileManager = FileManager.default
        do {
            // Delete the main store file
            if fileManager.fileExists(atPath: storeURL.path) {
                try fileManager.removeItem(at: storeURL)
                print("Deleted main store file: \(storeURL.path)")
            }
            
            // Delete related files (wal, shm, etc.)
            let relatedFiles = [
                "\(storeName)-wal",
                "\(storeName)-shm",
                "\(storeName).sqlite-wal",
                "\(storeName).sqlite-shm"
            ]
            
            for fileName in relatedFiles {
                let fileURL = storeDirectory.appendingPathComponent(fileName)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                    print("Deleted related file: \(fileURL.path)")
                }
            }
            
            print("Successfully deleted existing Core Data store")
        } catch {
            print("Error deleting Core Data store: \(error.localizedDescription)")
        }
    }
    
    /// Save user data to Core Data
    /// - Parameter user: The user to save
    func saveUser(_ user: User) throws {
        try user.validate()
        
        let context = persistentContainer.viewContext
        
        // Check if user already exists
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        
        let existingUsers = try context.fetch(fetchRequest)
        let userEntity: UserEntity
        
        if let existingUser = existingUsers.first {
            userEntity = existingUser
        } else {
            userEntity = UserEntity(context: context)
        }
        
        userEntity.updateFromUser(user)
        
        try context.save()
    }
    
    /// Fetch user by ID
    /// - Parameter id: The UUID of the user to fetch
    /// - Returns: Optional User if found
    func fetchUser(id: UUID) throws -> User? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let users = try context.fetch(fetchRequest)
        return users.first?.toUser()
    }
    
    /// Update existing user
    /// - Parameter user: The user to update
    /// - Returns: Updated user if successful
    func updateUser(_ user: User) throws -> User {
        try user.validate()
        
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)
        
        let users = try context.fetch(fetchRequest)
        guard let userEntity = users.first else {
            throw PersistenceError.updateFailed
        }
        
        userEntity.updateFromUser(user)
        try context.save()
        
        return user
    }
    
    /// Delete user by ID
    /// - Parameter id: The UUID of the user to delete
    func deleteUser(id: UUID) throws {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let users = try context.fetch(fetchRequest)
        for user in users {
            context.delete(user)
        }
        
        try context.save()
    }
    
    // MARK: - Lesson Management
    
    /// Save lesson data to Core Data
    /// - Parameter lesson: The lesson to save
    func saveLesson(_ lesson: Lesson) throws {
        let context = persistentContainer.viewContext
        
        // Check if lesson already exists
        let fetchRequest: NSFetchRequest<LessonEntity> = LessonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", lesson.id as CVarArg)
        
        let existingLessons = try context.fetch(fetchRequest)
        let lessonEntity: LessonEntity
        
        if let existingLesson = existingLessons.first {
            lessonEntity = existingLesson
        } else {
            lessonEntity = LessonEntity(context: context)
        }
        
        lessonEntity.updateFromLesson(lesson)
        
        // Link to user if exists
        let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        userFetchRequest.predicate = NSPredicate(format: "id == %@", lesson.userId as CVarArg)
        if let userEntity = try context.fetch(userFetchRequest).first {
            lessonEntity.user = userEntity
        }
        
        try context.save()
    }
    
    /// Fetch lessons by user ID
    /// - Parameter userId: The UUID of the user
    /// - Returns: Array of lessons for the user
    func fetchLessons(userId: UUID) throws -> [Lesson] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<LessonEntity> = LessonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let lessons = try context.fetch(fetchRequest)
        return lessons.map { $0.toLesson() }
    }
    
    /// Fetch completed lessons by user ID
    /// - Parameter userId: The UUID of the user
    /// - Returns: Array of completed lessons for the user
    func fetchCompletedLessons(userId: UUID) throws -> [Lesson] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<LessonEntity> = LessonEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND status == %@", userId as CVarArg, "completed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        let lessons = try context.fetch(fetchRequest)
        return lessons.map { $0.toLesson() }
    }
    
    // MARK: - Question Management
    
    /// Save question data to Core Data
    /// - Parameter question: The question to save
    func saveQuestion(_ question: Question) throws {
        let context = persistentContainer.viewContext
        
        // Check if question already exists
        let fetchRequest: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", question.id as CVarArg)
        
        let existingQuestions = try context.fetch(fetchRequest)
        let questionEntity: QuestionEntity
        
        if let existingQuestion = existingQuestions.first {
            questionEntity = existingQuestion
        } else {
            questionEntity = QuestionEntity(context: context)
        }
        
        questionEntity.updateFromQuestion(question)
        
        try context.save()
    }
    
    /// Fetch question by ID
    /// - Parameter id: The UUID of the question
    /// - Returns: Optional Question if found
    func fetchQuestion(id: UUID) throws -> Question? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let questions = try context.fetch(fetchRequest)
        return questions.first?.toQuestion()
    }
    
    /// Fetch questions by subject
    /// - Parameter subject: The subject to filter by
    /// - Returns: Array of questions for the subject
    func fetchQuestions(subject: Lesson.Subject) throws -> [Question] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "subject == %@", subject.rawValue)
        
        let questions = try context.fetch(fetchRequest)
        return questions.map { $0.toQuestion() }
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
