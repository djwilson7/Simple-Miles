//
//  TripPersistenceManager.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

final class TripPersistenceManager: TripPersistenceManagingProtocol {
    private let store: TripSessionStoringProtocol

    init(store: TripSessionStoringProtocol = TripSessionStore.shared) {
        print("[TripPersistenceManager] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.store = store
    }

    func save(_ trip: TripSessionModel) {
        print("[TripPersistenceManager] save triggered for tripID: \(trip.id)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        store.save(trip)
    }

    func clearAllTrips() {
        print("[TripPersistenceManager] clearAllTrips triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        store.clearAll()
    }

    func fetchAll() -> [TripSessionModel] {
        print("[TripPersistenceManager] fetchAll triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return store.fetchAll()
    }
}
