//
//  CSVExportingProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation

protocol CSVExportingProtocol {
    func export(from trips: [TripSessionModel]) -> URL?
}
