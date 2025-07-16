//
//  TripTrackingServiceProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

protocol TripTrackingServiceProtocol: AnyObject {
    var currentSession: TripSessionModel? { get }
    func startRecording()
    func stopRecording()
}
