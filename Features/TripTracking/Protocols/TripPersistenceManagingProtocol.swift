//
//  TripPersistenceManagingProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

protocol TripPersistenceManagingProtocol: AnyObject {
    func save(_ trip: TripSessionModel)
    func clearAllTrips()
    func fetchAll() -> [TripSessionModel]
}
