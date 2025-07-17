//
//  MockExportLauncher.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockExportLauncher: ExportLaunchingProtocol {
    var exportURL: URL?
    var isPresenting: Bool = false

    private(set) var launchedURL: URL?
    private(set) var didReset = false

    func launch(for url: URL?) {
        launchedURL = url
        isPresenting = true
        exportURL = url
    }

    func reset() {
        didReset = true
        exportURL = nil
        isPresenting = false
    }
}
