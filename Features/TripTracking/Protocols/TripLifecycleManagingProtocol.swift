//
//  TripLifecycleManagingProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

protocol TripLifecycleManagingProtocol: AnyObject {
    func startSession()
    func stopSession()
    var currentSession: TripSessionModel? { get }
    func resumeSession(from session: TripSessionModel)
}
