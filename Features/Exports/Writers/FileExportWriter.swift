//
//  FileExportWriter.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

enum FileExportWriter {
    static func write(content: String, fileName: String, fileExtension: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(fileName).\(fileExtension)")

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Failed to write file: \(error.localizedDescription)")
            return nil
        }
    }
}
