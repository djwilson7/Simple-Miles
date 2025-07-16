//
//  FileZipper.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Compression

enum FileZipper {
    static func zipFiles(_ files: [URL], zipName: String) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let folderURL = tempDir.appendingPathComponent(zipName)
        let zipURL = tempDir.appendingPathComponent("\(zipName).zip")

        // Create export folder
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        // Copy files into export folder
        for file in files {
            let destURL = folderURL.appendingPathComponent(file.lastPathComponent)
            try? fileManager.removeItem(at: destURL)
            try? fileManager.copyItem(at: file, to: destURL)
        }

        // Remove existing zip if present
        try? fileManager.removeItem(at: zipURL)

        // Compress folder
        let success = (try? CompressionHelper.zipFolder(at: folderURL, to: zipURL)) ?? false
        return success ? zipURL : nil
    }
}
