//
//  ExportLaunchingProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

protocol ExportLaunchingProtocol: AnyObject {
    var exportURL: URL? { get set }
    var isPresenting: Bool { get set }

    func launch(for url: URL?)
    func reset()
}
