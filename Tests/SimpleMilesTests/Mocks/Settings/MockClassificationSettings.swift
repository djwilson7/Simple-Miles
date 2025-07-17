//
//  MockClassificationSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockClassificationSettings: ClassificationSettingsProtocol {
    var defaultTripType: TripType = .business
}
