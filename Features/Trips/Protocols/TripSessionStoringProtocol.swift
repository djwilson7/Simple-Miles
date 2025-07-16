//
//  TripSessionStoringProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//
import Foundation

protocol TripSessionStoringProtocol {
    func fetchAll() -> [TripSessionModel]
    func save(_ model: TripSessionModel)
    func delete(sessionID: UUID)
    func update(_ updatedTrip: TripSessionModel)
}

