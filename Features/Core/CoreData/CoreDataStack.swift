//
//  CoreDataStack.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {
        print("[CoreDataStack] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
    }

    lazy var persistentContainer: NSPersistentContainer = {
        print("[CoreDataStack] loading persistent container") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let container = NSPersistentContainer(name: "SimpleMilesModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var mainContext: NSManagedObjectContext {
        print("[CoreDataStack] accessing mainContext") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return persistentContainer.viewContext
    }

    func backgroundContext() -> NSManagedObjectContext {
        print("[CoreDataStack] creating new background context") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return persistentContainer.newBackgroundContext()
    }

    func saveMainContext() {
        print("[CoreDataStack] saveMainContext triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let context = mainContext
        if context.hasChanges {
            do {
                try context.save()
                print("[CoreDataStack] mainContext saved successfully") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            } catch {
                print("[CoreDataStack] Error saving CoreData context: \(error)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            }
        } else {
            print("[CoreDataStack] save skipped – no changes detected") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        }
    }
}
