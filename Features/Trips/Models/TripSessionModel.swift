import Foundation

struct TripSessionModel: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    var endTime: Date?

    var distance: Double = 0.0
    var averageSpeed: Double {
        guard let end = endTime else { return 0.0 }
        let duration = end.timeIntervalSince(startTime)
        return duration > 0 ? distance / duration : 0.0
    }

    var path: [CoordinateModel] = []
    var tripType: TripType = .unclassified

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        distance: Double = 0.0,
        tripType: TripType = .unclassified,
        path: [CoordinateModel] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.tripType = tripType
        self.path = path
    }

    mutating func endSession(at time: Date) {
        self.endTime = time
    }
}
