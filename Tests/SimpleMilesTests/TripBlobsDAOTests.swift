import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("TripBlobsDAO Tests")
struct TripBlobsDAOTests {
    
    @Test("Write and Read Large Compressed Blob")
    func testLargeBlob() throws {
        let tripID = "large-blob-test"
        let data = Data(repeating: 0x41, count: 1024) // > 512 bytes
        let m = TripMeta(id: tripID, type: 1, startTs: 0, endTs: 0, distanceM: 0, durationS: 0, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        try TripsDAO.insertOrReplace(m)
        
        try TripBlobsDAO.writeCompressedBlob(tripID: tripID, kind: .raw, encodingVersion: 1, rawBytes: data, preferredCodec: .lzfse)
        
        let result = try TripBlobsDAO.readDecompressedBlob(tripID: tripID, kind: .raw)
        #expect(result?.bytes == data)
        #expect(result?.codec == "lzfse")
        
        try TripsDAO.delete(id: tripID)
    }
    
    @Test("Delete specific blob kind")
    func testDeleteSpecific() throws {
        let uniqueID = "delete-spec-\(UUID().uuidString)"
        let m = TripMeta(id: uniqueID, type: 1, startTs: 0, endTs: 0, distanceM: 0, durationS: 0, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        try TripsDAO.insertOrReplace(m)
        
        try TripBlobsDAO.writeCompressedBlob(tripID: uniqueID, kind: .raw, encodingVersion: 1, rawBytes: Data([1]))
        try TripBlobsDAO.writeCompressedBlob(tripID: uniqueID, kind: .display, encodingVersion: 1, rawBytes: Data([2]))
        
        try TripBlobsDAO.deleteBlobs(tripID: uniqueID, kind: .raw)
        #expect(try TripBlobsDAO.readDecompressedBlob(tripID: uniqueID, kind: .raw) == nil)
        #expect(try TripBlobsDAO.readDecompressedBlob(tripID: uniqueID, kind: .display) != nil)
        
        try TripsDAO.delete(id: uniqueID)
    }
}
