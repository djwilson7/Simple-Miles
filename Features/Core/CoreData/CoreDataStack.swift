//
//  CoreDataStack.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SimpleMilesModel")  // Matches your .xcdatamodeld name
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func backgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }

    func saveMainContext() {
        let context = mainContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving CoreData context: \(error)")
            }
        }
    }
}
