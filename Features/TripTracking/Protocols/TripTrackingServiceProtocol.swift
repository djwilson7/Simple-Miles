import Foundation
import Combine
import CoreLocation

protocol TripTrackingServiceProtocol: AnyObject {
    var currentSessionPublisher: Published<TripSessionModel?>.Publisher { get }
    var recordingState: any TripRecordingStateProtocol { get }
    var status: TripRecordingStatus { get } // ✅ Add this line
    var onTripSaved: (() -> Void)? { get set }
    var statusPublisher: Published<TripRecordingStatus>.Publisher { get }

    func startRecording()
    func stopRecording()
    func startPassiveMonitoring()
    func updateAnalyzerThresholds(speed: Double, distance: CLLocationDistance)
    func resumeRecording(from session: TripSessionModel)
    func clearAllTrips()
}


