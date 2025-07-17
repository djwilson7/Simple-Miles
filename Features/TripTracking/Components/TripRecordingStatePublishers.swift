//
//  TripRecordingStatePublishers.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Combine
import Foundation

struct TripRecordingStatePublishers {
    let isRecording: Published<Bool>.Publisher
    let totalDistance: Published<Double>.Publisher
    let loggedTripCoords: Published<Int>.Publisher
    let elapsedTime: Published<TimeInterval>.Publisher
    let remainingPauseTime: Published<TimeInterval>.Publisher
    let isPaused: Published<Bool>.Publisher
}


