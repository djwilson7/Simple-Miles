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
        String(format: "%.1f mi", trip.distance / 1609.34)
    }

    var durationText: String {
        let duration = (trip.endTime ?? Date()).timeIntervalSince(trip.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }

    var startDateText: String {
        DateFormatter.localizedString(from: trip.startTime, dateStyle: .medium, timeStyle: .short)
    }

    var endDateText: String {
        guard let end = trip.endTime else { return "In Progress" }
        return DateFormatter.localizedString(from: end, dateStyle: .medium, timeStyle: .short)
    }

    var segmentCount: Int {
        trip.segments.count
    }

    var startCoordinate: CoordinateModel {
        trip.segments.first?.startCoordinate ?? CoordinateModel(latitude: 0, longitude: 0)
    }

    var endCoordinate: CoordinateModel {
        trip.segments.last?.endCoordinate ?? CoordinateModel(latitude: 0, longitude: 0)
    }

    init(trip: TripSessionModel) {
        self.trip = trip
    }
}
