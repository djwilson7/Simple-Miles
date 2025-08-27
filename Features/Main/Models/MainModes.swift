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
    case summary = "summary"
    var id: String { rawValue }
}
