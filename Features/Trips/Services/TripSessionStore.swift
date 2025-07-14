//
//  TripSessionStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation
import CoreData

final class TripSessionStore {
    
    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Init

    init(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.context = context
    }

    // MARK: - Save

    func save(_ model: TripSessionModel) {
        _ = CDTripSession(from: model, context: context)
        commit()
    }

    // MARK: - Fetch

    func fetchAll() -> [TripSessionModel] {
        let request: NSFetchRequest<CDTripSession> = CDTripSession.fetchRequest()
        do {
            let results = try context.fetch(request)
            return results.map { $0.toModel() }
        } catch {
            print("CoreData fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Delete

    func delete(sessionID: UUID) {
        let request: NSFetchRequest<CDTripSession> = CDTripSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)

        do {
            let results = try context.fetch(request)
            for session in results {
                context.delete(session)
            }
            commit()
        } catch {
            print("Delete failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Internal

    private func commit() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save CoreData context: \(error.localizedDescription)")
        }
    }
}
