//
//  TripDetailViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class TripDetailViewModel: ObservableObject {
    @Published private(set) var trip: TripSessionModel

    var distanceText: String {
        print("[TripDetailViewModel] distanceText computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return String(format: "%.1f mi", trip.distance / 1609.34)
    }

    var durationText: String {
        print("[TripDetailViewModel] durationText computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let duration = (trip.endTime ?? Date()).timeIntervalSince(trip.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }

    var startDateText: String {
        print("[TripDetailViewModel] startDateText computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return DateFormatter.localizedString(from: trip.startTime, dateStyle: .medium, timeStyle: .short)
    }

    var endDateText: String {
        print("[TripDetailViewModel] endDateText computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let end = trip.endTime else { return "In Progress" }
        return DateFormatter.localizedString(from: end, dateStyle: .medium, timeStyle: .short)
    }

    var loggedPointCount: Int {
        print("[TripDetailViewModel] loggedPointCount computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return trip.path.count
    }

    var startCoordinate: CoordinateModel {
        print("[TripDetailViewModel] startCoordinate computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return trip.path.first ?? CoordinateModel(latitude: 0, longitude: 0)
    }

    var endCoordinate: CoordinateModel {
        print("[TripDetailViewModel] endCoordinate computed") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return trip.path.last ?? CoordinateModel(latitude: 0, longitude: 0)
    }

    init(trip: TripSessionModel) {
        self.trip = trip
    }
}
