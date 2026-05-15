import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SQLite3

@Suite("TripBlobsDAO Deep Tests")
struct TripBlobsDAODeepTests {
    
    @Test("Read empty blob")
    func testEmptyBlob() throws {
        let tripID = "empty-blob-test"
        let m = TripMeta(id: tripID, type: 1, startTs: 0, endTs: 0, distanceM: 0, durationS: 0, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        try TripsDAO.insertOrReplace(m)

        try TripBlobsDAO.writeCompressedBlob(tripID: tripID, kind: .raw, encodingVersion: 1, rawBytes: Data())

        let result = try TripBlobsDAO.readDecompressedBlob(tripID: tripID, kind: .raw)
        #expect(result?.bytes.isEmpty == true)

        try TripsDAO.delete(id: tripID)
    }
}
