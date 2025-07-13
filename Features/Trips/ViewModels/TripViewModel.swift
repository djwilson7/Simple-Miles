//
//  TripViewModel.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation
import Combine

class TripViewModel: ObservableObject {
    @Published var activeTrip: TripModel?
    @Published var tripHistory: [TripModel] = []

    func classifyTrip(_ id: UUID, as type: TripType) {
        // Reclassify trip logic
    }
}
