//
//  ExportLauncher.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class ExportLauncher {
    @Published var exportURL: URL?
    @Published var isPresenting: Bool = false

    func launch(for url: URL?) {
        guard let url = url else { return }
        self.exportURL = url
        self.isPresenting = true
    }

    func reset() {
        self.exportURL = nil
        self.isPresenting = false
    }
}
