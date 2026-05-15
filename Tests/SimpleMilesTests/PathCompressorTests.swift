import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("PathCompressor Tests")
struct PathCompressorTests {
    
    @Test("Compress and decompress LZFSE")
    func testLZFSE() {
        let input = "The quick brown fox jumps over the lazy dog".data(using: .utf8)!
        let compressed = PathCompressor.compress(input, codec: .lzfse)
        #expect(!compressed.isEmpty)
        
        let decompressed = PathCompressor.decompress(compressed, codec: .lzfse)
        #expect(decompressed == input)
    }
    
    @Test("Compress and decompress LZ4")
    func testLZ4() {
        let input = "The quick brown fox jumps over the lazy dog".data(using: .utf8)!
        let compressed = PathCompressor.compress(input, codec: .lz4)
        #expect(!compressed.isEmpty)
        
        let decompressed = PathCompressor.decompress(compressed, codec: .lz4)
        #expect(decompressed == input)
    }
    
    @Test("No compression")
    func testNone() {
        let input = "Hello".data(using: .utf8)!
        let compressed = PathCompressor.compress(input, codec: .none)
        #expect(compressed == input)
        
        let decompressed = PathCompressor.decompress(input, codec: .none)
        #expect(decompressed == input)
    }
    
    @Test("Codec raw values")
    func testCodecRaw() {
        #expect(PathCompressor.Codec(raw: "LZFSE") == .lzfse)
        #expect(PathCompressor.Codec(raw: "lz4") == .lz4)
        #expect(PathCompressor.Codec(raw: "invalid").raw == "none")
    }
}
