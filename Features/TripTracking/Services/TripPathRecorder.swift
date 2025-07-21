import Foundation
import CoreLocation

final class TripPathRecorder: TripPathRecordingProtocol {
    private(set) var coordinates: [CoordinateModel] = []

    func append(_ coordinate: CoordinateModel) {
        coordinates.append(coordinate)
        print("[TripPathRecorder] tick location: (\(coordinate.latitude), \(coordinate.longitude)) state: \(coordinate.state)") //DEBUG
    }

    func reset() {
        print("[TripPathRecorder] reset triggered") //DEBUG
        coordinates.removeAll()
    }
}
