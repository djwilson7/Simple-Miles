//
//  DrivingStateManger.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/22/25.
//

import Foundation
import CoreLocation
import Combine

final class DrivingStateManager: ObservableObject {
    @Published private(set) var state: Bool = false
    private var lastMovementTime: Date = Date()
    private var evaluationTimer: Timer?

    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    private let speedThreshold: CLLocationSpeed = 2.2 // m/s (~11 mph)
    private let startDistanceThreshold = 10.0
    private let pauseDistanceThreshold = 3.0

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        observeLocation()
    }

    private func observeLocation() {
        locationManager.$currentLocation
            .combineLatest(locationManager.$lastLocation, locationManager.$speed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current, last, speed in
                guard let self = self,
                      let current = current,
                      let last = last else {
                    self?.state = false
                    print("[DrivingStateManager] (observeLocation) - Driving state set to FALSE. Movement or speed did not meet threshold.")
                    return
                }

                let movedFarEnough = current.distance(from: last) > startDistanceThreshold
                let speedOK = speed > self.speedThreshold
                print("Moved Far Enough: \(movedFarEnough), speedOK \(speedOK)")
                if movedFarEnough && speedOK {
                    self.state = true
                    self.lastMovementTime = Date()
                    self.resetEvaluationTimer()
                    print("[DrivingStateManager] (observeLocation) - Driving state set to TRUE. Distance: \(current.distance(from: last)) > \(startDistanceThreshold), Speed: \(speed) > \(speedThreshold)")
                } else {
                    if current.distance(from: last) >= self.pauseDistanceThreshold {
                        self.lastMovementTime = Date()
                        print("[DrivingStateManager] (observeLocation) - Distance moved: \(current.distance(from: last)) >= \(pauseDistanceThreshold). Resetting lastMovementTime.")
                    }
                    print("[DrivingStateManager] (observeLocation) - Maintaining TRUE state. Distance: \(current.distance(from: last)), Speed: \(speed)")
                }
            }
            .store(in: &cancellables)
    }

    private func resetEvaluationTimer() {
        evaluationTimer?.invalidate()
        print("[DrivingStateManager] (Timer) - Evaluation timer reset. Waiting 120s for movement before setting state to FALSE.")
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.state {
                print("[DrivingStateManager] (Timer) - Timer expired with no movement detected. Transitioning to FALSE.")
                self.state = false
            }
        }
    }
}
