import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("Codec Helpers Tests")
struct CodecHelpersTests {
    
    @Test("Data read helpers")
    func testReadHelpers() {
        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
        #expect(data.readUInt16LE(at: 0) == 0x0201)
        #expect(data.readUInt32LE(at: 0) == 0x04030201)
        #expect(data.readInt32LE(at: 0) == 0x04030201)
        #expect(data.readInt64LE(at: 0) == 0x0807060504030201)
    }
    
    @Test("Data write helpers")
    func testWriteHelpers() {
        var data = Data()
        data.appendUInt32(0x04030201)
        data.appendInt32(0x08070605)
        data.appendInt64(1)
        data.appendUInt16(0x0201)
        #expect(data.count == 4 + 4 + 8 + 2)
    }
}
