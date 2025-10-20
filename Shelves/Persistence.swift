//
//  Persistence.swift
//  Shelves
//
//  Created by Brandon Titensor on 7/26/25.
//

import CoreData
import Foundation

extension Notification.Name {
    static let coreDataRecoveryRequired = Notification.Name("coreDataRecoveryRequired")
}

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let sampleBook = Book(context: viewContext)
        sampleBook.id = UUID()
        sampleBook.title = "The Hobbit"
        sampleBook.author = "J.R.R. Tolkien"
        sampleBook.isbn = "9780547928227"
        sampleBook.dateAdded = Date()
        sampleBook.libraryName = "Home Library"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Preview data save error: \(nsError), \(nsError.userInfo)")
            // Preview failures are non-critical, continue without sample data
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Shelves")

        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("⚠️ Core Data store loading error: \(error), \(error.userInfo)")

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 */

                // Attempt to recover by deleting the corrupted store
                var recoveryMessage = ""
                if let storeURL = storeDescription.url {
                    print("🔄 Attempting to recover by deleting corrupted store at: \(storeURL)")
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("✅ Successfully deleted corrupted store. App will restart with fresh database.")
                        recoveryMessage = "Your library database was corrupted and has been reset. You'll need to re-import your books."
                    } catch {
                        print("❌ Failed to delete corrupted store: \(error.localizedDescription)")
                        recoveryMessage = "Unable to access your library database. Please restart the app."
                    }
                }

                // Notify the app about the recovery so it can show an alert
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .coreDataRecoveryRequired,
                        object: nil,
                        userInfo: ["message": recoveryMessage]
                    )
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
