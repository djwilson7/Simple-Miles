//
//  TriprecordingStateProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
import Combine

protocol TripRecordingStateProtocol: AnyObject, ObservableObject {
    var isRecording: Bool { get set }
    var session: TripSessionModel? { get set }
    var elapsedTime: TimeInterval { get set }
    var loggedTripCoords: Int { get set }
    var totalDistance: Double { get set }
    var pauseExpiresAt: Date? { get set }
    var remainingPauseTime: TimeInterval { get set }
    var isPaused: Bool { get }

    var publisherValues: TripRecordingStatePublishers { get }

    func update(with session: TripSessionModel?)
    func reset()
    func startTimer()
    func stopTimer()
    func startPauseCountdown(duration: TimeInterval)
    func resetPauseCountdown(duration: TimeInterval)
    func cancelPauseCountdown()
}
