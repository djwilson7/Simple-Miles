//
//  DistanceUnit.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//
import Foundation

enum DistanceUnit: String, CaseIterable {
    case miles
    case kilometers

    var label: String {
        switch self {
        case .miles: "Miles"
        case .kilometers: "Kilometers"
        }
    }

    var abbreviation: String {
        switch self {
        case .miles: "mi"
        case .kilometers: "km"
        }
    }

    var metersPerUnit: Double {
        switch self {
        case .miles: 1609.34
        case .kilometers: 1000.0
        }
    }

    func format(distanceInMeters: Double, decimals: Int = 2) -> String {
        let converted = distanceInMeters / metersPerUnit
        return String(format: "%.\(decimals)f", converted) + " \(abbreviation)"
    }
}

