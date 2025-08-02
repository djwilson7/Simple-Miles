//
//  SettingsViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/27/25.
//

import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var settings = AppSettings.shared

    // Add any computed bindings or other view model logic here
}
