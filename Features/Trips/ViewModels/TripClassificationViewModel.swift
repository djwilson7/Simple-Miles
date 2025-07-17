//
//  TripClassificationViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class TripClassificationViewModel: ObservableObject {
    @Published private(set) var trip: TripSessionModel

    private let store: TripSessionStoringProtocol

    init(
        trip: TripSessionModel,
        store: TripSessionStoringProtocol = TripSessionStore()
    ) {
        self.trip = trip
        self.store = store
    }

    func updateClassification(to type: TripType) {
        print("[TripClassificationViewModel] updateClassification triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        trip.tripType = type
        store.update(trip)
    }

    func currentClassificationLabel() -> String {
        print("[TripClassificationViewModel] currentClassificationLabel triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return trip.tripType.rawValue
    }

    func isClassified(as type: TripType) -> Bool {
        print("[TripClassificationViewModel] isClassified triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return trip.tripType == type
    }
}
