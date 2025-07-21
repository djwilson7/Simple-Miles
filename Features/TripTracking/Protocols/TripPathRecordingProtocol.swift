import Foundation
import CoreLocation

protocol TripPathRecordingProtocol: AnyObject {
    var coordinates: [CoordinateModel] { get }
    func append(_ coordinate: CoordinateModel)
    func reset()
}
