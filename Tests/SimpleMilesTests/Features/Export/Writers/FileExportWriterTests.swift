//
//  FileExportWriterTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class FileExportWriterTests: XCTestCase {
    func testWriteCreatesFileWithCorrectNameAndExtension() throws {
        let result = try XCTUnwrap(FileExportWriter.write(content: "test", fileName: "unit_test", fileExtension: "csv"))
        XCTAssertTrue(result.path.contains("unit_test"))
        XCTAssertTrue(result.path.hasSuffix(".csv"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testWriteFailsGracefullyOnIllegalCharacters() {
        let invalidName = "invalid:/\\*?"
        let result = FileExportWriter.write(content: "test", fileName: invalidName, fileExtension: "csv")
        XCTAssertNil(result, "Should return nil when given illegal file name")
    }

    func testTimestampIsFormattedCorrectly() {
        let result = FileExportWriter.write(content: "test", fileName: "test", fileExtension: "txt")
        let name = result?.lastPathComponent ?? ""
        XCTAssertTrue(name.range(of: #"test_\d{8}_\d{6}\.txt"#, options: .regularExpression) != nil)
    }
    
    func testWriteOverwritesFileWithSameName() throws {
        let name = "conflict_test"
        let firstURL = try XCTUnwrap(FileExportWriter.write(content: "first", fileName: name, fileExtension: "txt"))
        let secondURL = try XCTUnwrap(FileExportWriter.write(content: "second", fileName: name, fileExtension: "txt"))

        XCTAssertEqual(firstURL.lastPathComponent, secondURL.lastPathComponent, "File name should remain the same")
        
        let contents = try String(contentsOf: secondURL, encoding: .utf8)
        XCTAssertEqual(contents, "second", "File should reflect the latest write")
    }
    
    func testWriteFailsToProtectedDirectory() {
        let protectedURL = URL(fileURLWithPath: "/System/Library/test.txt")
        do {
            try "fail".write(to: protectedURL, atomically: true, encoding: .utf8)
            XCTFail("Should not be able to write to protected system directory")
        } catch {
            XCTAssertTrue(true)
        }
    }

}
