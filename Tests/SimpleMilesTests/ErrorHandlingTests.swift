import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SQLite3

@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    
    @Test("lastError helpers")
    func testLastError() {
        let db = Database.shared
        db.inRead { handle in
            let err1 = db.lastError(handle)
            let err2 = TripsDAO.lastError(handle)
            let err3 = TripBlobsDAO.lastError(handle)
            #expect(!err1.isEmpty)
            #expect(!err2.isEmpty)
            #expect(!err3.isEmpty)
        }
    }
    
    @Test("DBError descriptions")
    func testDBError() {
        let e1 = DBError.openFailed(message: "test")
        let e2 = DBError.sqlite(message: "test")
        let e3 = DBError.closed
        
        #expect(e1.errorDescription?.contains("open failed") == true)
        #expect(e2.errorDescription?.contains("SQLite error") == true)
        #expect(e3.errorDescription?.contains("closed") == true)
    }
}
