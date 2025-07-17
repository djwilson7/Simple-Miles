//
//  MockTripPersistenceManager.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockTripPersistenceManager: TripPersistenceManagingProtocol {
    private(set) var didSave = false
    private(set) var didClear = false
    var savedTrip: TripSessionModel?

    func save(_ trip: TripSessionModel) {
        didSave = true
        savedTrip = trip
    }

    func clearAllTrips() {
        didClear = true
    }

    func fetchAll() -> [TripSessionModel] {
        []
    }
}
