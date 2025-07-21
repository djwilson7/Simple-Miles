//
//  TripType.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

enum TripType: String, Codable, CaseIterable, CustomStringConvertible {
    case business = "Business"
    case personal = "Personal"
    case unclassified = "Unclassified"
    
    var description: String {
        switch self {
        case .business: rawValue
        case .personal: rawValue
        case .unclassified: rawValue
        }
    }
}

