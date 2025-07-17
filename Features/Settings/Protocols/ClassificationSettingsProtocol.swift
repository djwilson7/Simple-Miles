//
//  ClassificationSettingsProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
import Foundation

protocol ClassificationSettingsProtocol: ObservableObject {
    var defaultTripType: TripType { get set }
}
