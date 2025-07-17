//
//  TripExportViewModelProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

protocol TripExportViewModelProtocol: AnyObject {
    var store: TripSessionStoringProtocol { get }

    func generateCSVExport() -> URL?
    func generateJSONBackup() -> URL?
}
