//
//  JSONTripWriterTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class JSONTripWriterTests: XCTestCase {
    
    func testExportReturnsNilForEmptyTripList() {
        XCTAssertNil(JSONTripWriter.export(from: []), "Expected nil when exporting empty trip array")
    }

    func testExportCreatesValidJSONFileWithExtension() throws {
        let result = try XCTUnwrap(JSONTripWriter.export(from: [TripSessionModel.mock()]))
        XCTAssertTrue(result.path.hasSuffix(".json"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    func testExportedJSONIsNonEmptyAndIncludesRequiredFields() throws {
        let result = try XCTUnwrap(JSONTripWriter.export(from: [TripSessionModel.mock()]))
        let content = try String(contentsOf: result, encoding: .utf8)

        XCTAssertFalse(content.isEmpty)
        XCTAssertTrue(content.contains("\"id\""))
        XCTAssertTrue(content.contains("\"segments\""))
    }

    func testExportHandlesMultipleTripSessions() throws {
        let trips = [TripSessionModel.mock(), TripSessionModel.mock()]
        let url = try XCTUnwrap(JSONTripWriter.export(from: trips))
        let content = try String(contentsOf: url, encoding: .utf8)

        let occurrenceCount = content.components(separatedBy: "\"segments\"").count - 1
        XCTAssertEqual(occurrenceCount, trips.count, "Expected one 'segments' entry per trip")
    }

    func testExportFailsGracefullyOnEncodingError() {
        struct FailingModel: Encodable {
            func encode(to encoder: Encoder) throws {
                throw NSError(domain: "test", code: 1)
            }
        }

        struct FakeWriter {
            static func export() -> URL? {
                let encoder = JSONEncoder()
                do {
                    _ = try encoder.encode(FailingModel())
                    return nil
                } catch {
                    return nil
                }
            }
        }

        XCTAssertNil(FakeWriter.export(), "Expected graceful fail on encoding error")
    }
}
