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
        print("[TripSessionStore] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.context = context
    }

    func save(_ model: TripSessionModel) {
        print("[TripSessionStore] save triggered for tripID: \(model.id)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        _ = CDTripSession(from: model, context: context)
        commit()
    }

    func fetchAll() -> [TripSessionModel] {
        print("[TripSessionStore] fetchAll triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let request: NSFetchRequest<CDTripSession> = CDTripSession.fetchRequest()
        do {
            let results = try context.fetch(request)
            print("[TripSessionStore] fetchAll returned \(results.count) results") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return results.map { $0.toModel() }
        } catch {
            print("[TripSessionStore] CoreData fetch failed: \(error.localizedDescription)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return []
        }
    }

    func delete(sessionID: UUID) {
        print("[TripSessionStore] delete triggered for sessionID: \(sessionID)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let request: NSFetchRequest<CDTripSession> = CDTripSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)

        do {
            let results = try context.fetch(request)
            print("[TripSessionStore] \(results.count) sessions matched for deletion") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            for session in results {
                context.delete(session)
            }
            commit()
        } catch {
            print("[TripSessionStore] Delete failed: \(error.localizedDescription)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        }
    }

    func update(_ updatedTrip: TripSessionModel) {
        print("[TripSessionStore] update triggered for tripID: \(updatedTrip.id)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        delete(sessionID: updatedTrip.id)
        save(updatedTrip)
    }

    func clearAll() {
        print("[TripSessionStore] clearAll triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDTripSession")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            print("[TripSessionStore] All trip sessions deleted from CoreData") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        } catch {
            print("[TripSessionStore] Failed to clear trips: \(error.localizedDescription)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        }
    }

    private func commit() {
        guard context.hasChanges else {
            print("[TripSessionStore] commit skipped – no changes to save") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }
        do {
            try context.save()
            print("[TripSessionStore] context successfully saved") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        } catch {
            print("[TripSessionStore] Failed to save CoreData context: \(error.localizedDescription)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        }
    }
}
