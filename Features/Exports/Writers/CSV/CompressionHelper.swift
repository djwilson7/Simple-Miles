//
//  CompressionHelper.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import ZIPFoundation

enum CompressionHelper {
    static func zipFolder(at folderURL: URL, to zipURL: URL) throws -> Bool {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: folderURL.path) else { return false }

        let archive = try Archive(url: zipURL, accessMode: .create)

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: resourceKeys) else { return false }

        for case let fileURL as URL in enumerator {
            let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard !isDirectory else { continue }

            let relativePath = fileURL.path.replacingOccurrences(of: folderURL.path + "/", with: "")
            try archive.addEntry(with: relativePath, fileURL: fileURL)
        }

        return true
    }
}
