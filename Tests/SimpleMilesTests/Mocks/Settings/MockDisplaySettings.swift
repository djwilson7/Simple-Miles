//
//  MockDisplaySettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockDisplaySettings: DisplaySettingsProtocol {
    var distanceUnit: DistanceUnit = .miles
    var timeFormat: TimeFormat = .twentyFourHour
}
