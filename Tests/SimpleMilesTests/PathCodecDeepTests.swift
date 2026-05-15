import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("PathCodec Deep Tests")
struct PathCodecDeepTests {
    
    @Test("Empty path handling")
    func testEmpty() throws {
        let encoded = try PathEncoder.encodeDisplay(coords: [])
        #expect(encoded.isEmpty)
        
        #expect(throws: PathDecodeError.empty) {
            try PathDecoder.decodeDisplay(Data(), codec: "lzfse", version: 1)
        }
    }
    
    @Test("PathDecoder truncated payload")
    func testTruncated() {
        let coords = [CLLocationCoordinate2D(latitude: 0, longitude: 0)]
        let encoded = try! PathEncoder.encodeDisplay(coords: coords)
        let truncated = encoded.prefix(5) // Too short for header
        
        #expect(throws: PathDecodeError.truncated) {
            try PathDecoder.decodeDisplay(truncated, codec: "lzfse", version: 1)
        }
    }

    @Test("PathDecodeError cases")
    func testPathDecodeErrors() {
        // Bad Magic
        var badMagic = Data([0x00, 0x00, 0x00, 0x00, 1, 0, 0])
        badMagic.append(Data(repeating: 0, count: 50))
        #expect(throws: PathDecodeError.badMagic) {
            try PathDecoder.decodeDisplay(badMagic, codec: "lzfse", version: 1)
        }
        
        // Unsupported Version Header
        var badVer = Data([0x53, 0x4D, 0x50, 0x54, 99, 0, 0])
        badVer.append(Data(repeating: 0, count: 50))
        #expect(throws: PathDecodeError.unsupportedVersion(99)) {
            try PathDecoder.decodeDisplay(badVer, codec: "lzfse", version: 1)
        }

        // Unsupported Version Parameter
        let validPayload = try! PathEncoder.encodeDisplay(coords: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 1, longitude: 1)
        ])
        #expect(throws: PathDecodeError.unsupportedVersion(99)) {
            try PathDecoder.decodeDisplay(validPayload, codec: "lzfse", version: 99)
        }
        
        // Unsupported Codec
        #expect(throws: PathDecodeError.unsupportedCodec("invalid")) {
            try PathDecoder.decodeDisplay(validPayload, codec: "invalid", version: 1)
        }
    }

    @Test("Decode with raw codec")
    func testRawCodec() throws {
        var header = Data([0x53, 0x4D, 0x50, 0x54]) // Magic
        header.append(1) // Ver
        header.append(0) // Flags
        header.append(0) // Reserved
        header.appendUInt32(1) // Count
        header.appendInt32(Int32(10 * 1_000_000)) // Lat0
        header.appendInt32(Int32(10 * 1_000_000)) // Lon0
        for _ in 1...4 { header.appendInt32(0) } // bbox
        
        let decoded = try PathDecoder.decodeDisplay(header, codec: "none", version: 1)
        #expect(decoded.count == 1)
        #expect(decoded.first?.latitude == 10)
    }
}
