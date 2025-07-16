//
//  TripSessionStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation
import CoreData

final class TripSessionStore: TripSessionStoringProtocol {
    static let shared = TripSessionStore()

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.context = context
    }

    func save(_ model: TripSessionModel) {
        _ = CDTripSession(from: model, context: context)
        commit()
    }

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

    func update(_ updatedTrip: TripSessionModel) {
        delete(sessionID: updatedTrip.id)
        save(updatedTrip)
    }

    func clearAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDTripSession")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            print("[Storage] All trip sessions deleted from CoreData")
        } catch {
            print("[Storage] Failed to clear trips: \(error.localizedDescription)")
        }
    }

    private func commit() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save CoreData context: \(error.localizedDescription)")
        }
    }
}
