//
//  AppStateReader.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import UIKit

final class AppStateReader: ApplicationStateReadingProtocol {
    var backgroundRefreshStatus: UIBackgroundRefreshStatus {
        UIApplication.shared.backgroundRefreshStatus
    }
}
