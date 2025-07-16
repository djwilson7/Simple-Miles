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
        trip.tripType = type
        store.update(trip)
    }

    func currentClassificationLabel() -> String {
        trip.tripType.rawValue
    }

    func isClassified(as type: TripType) -> Bool {
        trip.tripType == type
    }
}
