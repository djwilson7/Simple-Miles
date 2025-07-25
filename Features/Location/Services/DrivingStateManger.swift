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
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                guard let self = self,
                      let last = self.locationManager.lastLocation else {
                    self?.state = false
                    return
                }

                let movedFarEnough = current.distance(from: last) > self.startDistanceThreshold
                let speedOK = self.locationManager.speed > self.speedThreshold
                print("Moved Far Enough: \(movedFarEnough), speedOK \(speedOK)")

                if movedFarEnough && speedOK {
                    self.resetEvaluationTimer()
                    if self.state == false {
                        self.state = true
                        self.lastMovementTime = Date()
                    }
                } else {
                    if current.distance(from: last) >= self.pauseDistanceThreshold {
                        self.lastMovementTime = Date()
                        print("\(self.lastMovementTime)")
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func resetEvaluationTimer() {
        evaluationTimer?.invalidate()
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.state && Date().timeIntervalSince(self.lastMovementTime) > 10 {
                self.state = false
            }
        }
    }
}
