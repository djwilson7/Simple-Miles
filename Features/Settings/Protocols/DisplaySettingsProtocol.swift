//
//  DisplaySettingsProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
import Foundation

protocol DisplaySettingsProtocol: ObservableObject {
    var distanceUnit: DistanceUnit { get set }
    var timeFormat: TimeFormat { get set }
}
