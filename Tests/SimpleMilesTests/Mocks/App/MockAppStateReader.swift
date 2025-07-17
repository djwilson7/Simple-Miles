//
//  MockAppStateReader.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
import UIKit
@testable import SimpleMiles

final class MockAppStateReader: ApplicationStateReadingProtocol {
    var backgroundRefreshStatus: UIBackgroundRefreshStatus = .available
}

