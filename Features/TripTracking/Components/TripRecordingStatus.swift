//
//  TripRecordingStatus.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//
import SwiftUI

enum TripRecordingStatus {
    case idle, recording, paused

    var displayText: String {
        switch self {
        case .idle: return "Idle"
        case .recording: return "Recording"
        case .paused: return "Paused"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .gray
        case .recording: return .green
        case .paused: return .orange
        }
    }
}

