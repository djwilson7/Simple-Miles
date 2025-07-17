//
//  TripLifecycleManger.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

final class TripLifecycleManager: TripLifecycleManagingProtocol {
    private(set) var currentSession: TripSessionModel?

    func startSession() {
        print("[TripLifecycleManager] startSession triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        currentSession = TripSessionModel()
    }

    func stopSession() {
        print("[TripLifecycleManager] stopSession triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        currentSession?.endTime = Date()
    }
    
    func resumeSession(from session: TripSessionModel) {
        print("[TripLifecycleManager] resumeSession triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        currentSession = session
    }
}
