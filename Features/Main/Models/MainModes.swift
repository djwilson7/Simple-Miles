//
//  MainModes.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/10/25.
//

import Foundation

enum MainModes: String, CaseIterable, Identifiable {
    case main = "main"
    case settings = "settings"
    case review = "review"
    var id: String { rawValue }
}
