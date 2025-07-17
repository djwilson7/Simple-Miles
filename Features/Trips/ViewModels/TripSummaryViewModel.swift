//
//  TripSummaryViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class TripSummaryViewModel: ObservableObject {
    @Published private(set) var totalDistance: Double = 0
    @Published private(set) var totalTrips: Int = 0
    @Published private(set) var classifiedTrips: [TripType: Int] = [:]

    private let store: TripSessionStoringProtocol

    init(store: TripSessionStoringProtocol = TripSessionStore()) {
        self.store = store
        loadSummary()
    }

    func loadSummary() {
        print("[TripSummaryViewModel] loadSummary triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let trips = store.fetchAll()

        totalTrips = trips.count
        totalDistance = trips.reduce(0) { $0 + $1.distance }

        classifiedTrips = Dictionary(grouping: trips, by: \.tripType)
            .mapValues { $0.count }
    }

    func tripCount(for type: TripType) -> Int {
        print("[TripSummaryViewModel] tripCount triggered for type: \(type)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return classifiedTrips[type] ?? 0
    }

    func percentage(for type: TripType) -> Double {
        print("[TripSummaryViewModel] percentage triggered for type: \(type)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard totalTrips > 0 else { return 0 }
        let count = tripCount(for: type)
        return Double(count) / Double(totalTrips)
    }

    func formattedTotalDistance() -> String {
        print("[TripSummaryViewModel] formattedTotalDistance triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return String(format: "%.1f mi", totalDistance / 1609.34)
    }
}
