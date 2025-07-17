//
//  Untitled.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import CoreLocation

protocol MovementMonitoringProtocol: AnyObject {
    func updateThresholds(speed: CLLocationSpeed, distance: CLLocationDistance)
    func startPassiveMonitoring()
    func analyze(location: CLLocation)
    func resetState()

    var onShouldStartTrip: (() -> Void)? { get set }
    var onShouldResumeTrip: (() -> Void)? { get set }
    var onShouldPauseTrip: (() -> Void)? { get set }
}
