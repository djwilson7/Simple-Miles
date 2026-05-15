import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("PathCodec Tests")
struct PathCodecTests {
    
    @Test("Encode and Decode Display Path")
    func testDisplayPathCodec() throws {
        let coords = [
            CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
            CLLocationCoordinate2D(latitude: 37.3320, longitude: -122.0330),
            CLLocationCoordinate2D(latitude: 37.3325, longitude: -122.0335)
        ]
        
        let encoded = try PathEncoder.encodeDisplay(coords: coords)
        #expect(!encoded.isEmpty)
        
        let decoded = try PathDecoder.decodeDisplay(encoded, codec: "lzfse", version: 1)
        #expect(decoded.count == coords.count)
        
        for (c1, c2) in zip(coords, decoded) {
            #expect(abs(c1.latitude - c2.latitude) < 0.0001)
            #expect(abs(c1.longitude - c2.longitude) < 0.0001)
        }
    }

    @Test("Various deltas")
    func testVariousDeltas() throws {
        let coords = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0.000001, longitude: 0.000001), // Smallest step
            CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0),
            CLLocationCoordinate2D(latitude: -1.0, longitude: -1.0)
        ]
        let encoded = try PathEncoder.encodeDisplay(coords: coords)
        let decoded = try PathDecoder.decodeDisplay(encoded, codec: "lzfse", version: 1)
        #expect(decoded.count == 4)
    }
    
    @Test("PathDecoder bad magic")
    func testBadMagic() {
        let badData = Data([0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00])
        #expect(throws: PathDecodeError.badMagic) {
            try PathDecoder.decodeDisplay(badData, codec: "lzfse", version: 1)
        }
    }

    @Test("PathDecoder truncated payload")
    func testTruncated() {
        let badData = Data([0x53, 0x4D, 0x50, 0x54, 0x01]) // Truncated header
        #expect(throws: PathDecodeError.truncated) {
            try PathDecoder.decodeDisplay(badData, codec: "lzfse", version: 1)
        }
    }

    @Test("PathDecodeError cases")
    func testErrorDescriptions() {
        #expect(PathDecodeError.empty.errorDescription == "Empty payload")
        #expect(PathDecodeError.badMagic.errorDescription == "Bad payload magic header")
        #expect(PathDecodeError.unsupportedVersion(2).errorDescription == "Unsupported payload version: 2")
        #expect(PathDecodeError.unsupportedCodec("unknown").errorDescription == "Unsupported codec: unknown")
        #expect(PathDecodeError.truncated.errorDescription == "Payload truncated")
        #expect(PathDecodeError.corrupt.errorDescription == "Payload corrupt")
    }

    @Test("Empty path handling")
    func testEmptyPath() throws {
        let encoded = try PathEncoder.encodeDisplay(coords: [])
        #expect(encoded.isEmpty)
        
        #expect(throws: PathDecodeError.empty) {
            try PathDecoder.decodeDisplay(encoded, codec: "lzfse", version: 1)
        }
    }

    @Test("Decode with raw codec")
    func testRawCodec() throws {
        _ = [CLLocationCoordinate2D(latitude: 10, longitude: 20)]
        
        var header = Data([0x53, 0x4D, 0x50, 0x54, 1, 0, 0])
        header.appendUInt32(1)
        header.appendInt32(10_000_000)
        header.appendInt32(20_000_000)
        // bbox: minLat, minLon, maxLat, maxLon (16 bytes total)
        for _ in 1...4 { header.appendInt32(0) }
        
        let decoded = try PathDecoder.decodeDisplay(header, codec: "raw", version: 1)
        #expect(decoded.count == 1)
        #expect(decoded[0].latitude == 10)
    }

    @Test("Unsupported version or codec")
    func testUnsupported() throws {
        let coords = [
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
            CLLocationCoordinate2D(latitude: 1.1, longitude: 1.1)
        ]
        let encoded = try PathEncoder.encodeDisplay(coords: coords)
        
        #expect(throws: PathDecodeError.unsupportedVersion(2)) {
            try PathDecoder.decodeDisplay(encoded, codec: "lzfse", version: 2)
        }
        
        #expect(throws: PathDecodeError.unsupportedCodec("zip")) {
            try PathDecoder.decodeDisplay(encoded, codec: "zip", version: 1)
        }
    }
}
