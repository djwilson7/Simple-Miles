import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("TripType Tests")
struct TripTypeTests {
    
    @Test("Mappings")
    func testMappings() {
        #expect(TripType(dbValue: 0) == .personal)
        #expect(TripType(dbValue: 1) == .business)
        #expect(TripType(dbValue: 2) == .custom)
        #expect(TripType(dbValue: 3) == .unsorted)
        #expect(TripType(dbValue: 4) == .trash)
        #expect(TripType(dbValue: 5) == nil)
        
        #expect(TripType.personal.dbValue == 0)
        #expect(TripType.business.dbValue == 1)
        #expect(TripType.custom.dbValue == 2)
        #expect(TripType.unsorted.dbValue == 3)
        #expect(TripType.trash.dbValue == 4)
    }
    
    @Test("URL Prefix")
    func testUrlPrefix() {
        #expect(TripType.business.urlPrefix == "business_")
    }
}
