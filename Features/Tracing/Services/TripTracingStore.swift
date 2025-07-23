import Foundation
import CoreLocation

import Combine

final class TripTraceStore: ObservableObject {
    private var isRecording: Bool = false
    private var travelState: TravelStateManager.TravelState = .idle
    private var currentLocation: CLLocation?
    private var lastLocation: CLLocation?
    @Published private(set) var lastSegment: (CLLocationCoordinate2D, CLLocationCoordinate2D)?

    private var lastCoordinate: CLLocationCoordinate2D?
    private var cancellables = Set<AnyCancellable>()

    init(
        isRecordingPublisher: Published<Bool>.Publisher,
        travelStatePublisher: Published<TravelStateManager.TravelState>.Publisher,
        currentLocationPublisher: Published<CLLocation?>.Publisher,
        lastLocationPublisher: Published<CLLocation?>.Publisher
    ) {
        isRecordingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isRecording = value
            }
            .store(in: &cancellables)

        travelStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.travelState = state
            }
            .store(in: &cancellables)

        currentLocationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let currentLocation = location else { return }
                self?.append(currentLocation)
            }
            .store(in: &cancellables)
        
        lastLocationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let lastLocation = location else { return }
                self?.append(lastLocation)
            }
            .store(in: &cancellables)
    }

    func append(_ location: CLLocation) {
        guard isRecording, travelState == .traveling else {
            print("[TripTraceStore] Skipping coordinate append; not recording or not traveling.")
            return
        }
        let newCoord = location.coordinate
        print("[TripTraceStore] Received new coordinate: \(newCoord)")
        print("[TripTraceStore] Last coordinate: \(String(describing: lastCoordinate))")
        guard newCoord.latitude != lastCoordinate?.latitude || newCoord.longitude != lastCoordinate?.longitude else {
            print("[TripTraceStore] Duplicate coordinate detected. Skipping update.")
            return
        }
        if let last = lastCoordinate {
            lastSegment = (last, newCoord)
            print("[TripTraceStore] New segment created: (\(last) -> \(newCoord))")
        }
        lastLocation = currentLocation
        currentLocation = location
        lastCoordinate = newCoord
    }

    func reset() {
        print("[TripTraceStore] Resetting trace store.")
        lastCoordinate = nil
        lastSegment = nil
    }
}
