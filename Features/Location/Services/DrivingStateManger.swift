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
    private var lastEvaluatedLocation: CLLocation?

    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    private let movementDistanceThreshold: CLLocationDistance = 10.0
    private let speedThreshold: CLLocationSpeed = 0.5 // ~1.1 mph

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        observeLocation()
    }

    private func observeLocation() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                self?.evaluateMotion(current: current)
            }
            .store(in: &cancellables)
    }

    private func evaluateMotion(current: CLLocation) {
        guard let last = lastEvaluatedLocation else {
            lastEvaluatedLocation = current
            return
        }

        let distance = current.distance(from: last)
        let speed = locationManager.speed

        if distance > movementDistanceThreshold && speed > speedThreshold {
            lastEvaluatedLocation = current
            lastMovementTime = Date()
            resetEvaluationTimer()
            if !state {
                state = true
            }
        }
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
