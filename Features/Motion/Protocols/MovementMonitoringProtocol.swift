import CoreLocation

protocol MovementMonitoringProtocol: AnyObject {
    func startPassiveMonitoring()
    func resetState()
    func analyze(location: CLLocation)
    func updateThresholds(speed: CLLocationSpeed, distance: CLLocationDistance)
    func updateLastLocation(_ location: CLLocation)

    var onShouldStartTrip: (() -> Void)? { get set }
    var onShouldResumeTrip: (() -> Void)? { get set }
    var onShouldPauseTrip: (() -> Void)? { get set }
    var onShouldStopTrip: (() -> Void)? { get set }
}
