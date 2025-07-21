import Foundation
import Combine
import CoreLocation

protocol LocationServiceProtocol: AnyObject {
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var headingPublisher: AnyPublisher<CLLocationDirection, Never> { get }
    var lastKnownLocation: CLLocation? { get }

    func initialize()
    func stopTracking()
}
