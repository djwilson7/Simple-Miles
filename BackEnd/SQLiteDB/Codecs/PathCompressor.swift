import Foundation
import Compression

public enum PathCompressor {

    public enum Codec: String { case lzfse, lz4, none }

    public static func compress(_ data: Data, codec: Codec = .lzfse) -> Data {
        switch codec {
        case .none: return data
        case .lzfse: return transcode(data, operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_LZFSE)
        case .lz4:   return transcode(data, operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_LZ4)
        }
    }

    public static func decompress(_ data: Data, codec: Codec) -> Data {
        switch codec {
        case .none: return data
        case .lzfse: return transcode(data, operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_LZFSE)
        case .lz4:   return transcode(data, operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_LZ4)
        }
    }

    private static func transcode(_ input: Data, operation: compression_stream_operation, algorithm: compression_algorithm) -> Data {
        guard !input.isEmpty else { return input }

        switch operation {
        case COMPRESSION_STREAM_ENCODE:
            return input.withUnsafeBytes { (srcBuf: UnsafeRawBufferPointer) -> Data in
                guard let src = srcBuf.bindMemory(to: UInt8.self).baseAddress else { return input }
                var dstCapacity = max(1024, input.count + 8192)
                while dstCapacity < Int.max / 2 {
                    let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                    defer { dst.deallocate() }
                    let written = compression_encode_buffer(dst, dstCapacity, src, input.count, nil, algorithm)
                    if written > 0 {
                        return Data(bytes: dst, count: written)
                    }
                    dstCapacity *= 2
                }
                return input
            }

        case COMPRESSION_STREAM_DECODE:
            return input.withUnsafeBytes { (srcBuf: UnsafeRawBufferPointer) -> Data in
                guard let src = srcBuf.bindMemory(to: UInt8.self).baseAddress else { return input }
                var dstCapacity = max(4096, input.count * 4)
                while dstCapacity <= 64 * 1024 * 1024 {
                    let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                    defer { dst.deallocate() }
                    let written = compression_decode_buffer(dst, dstCapacity, src, input.count, nil, algorithm)
                    if written > 0 {
                        return Data(bytes: dst, count: written)
                    }
                    dstCapacity *= 2
                }
                return Data()
            }

        default:
            return input
        }
    }
}

public extension PathCompressor.Codec {
    init(raw: String?) {
        switch raw?.lowercased() {
        case "lzfse": self = .lzfse
        case "lz4":   self = .lz4
        case "none":  fallthrough
        case nil:      self = .none
        default:       self = .none
        }
    }

    var raw: String {
        switch self {
        case .lzfse: return "lzfse"
        case .lz4:   return "lz4"
        case .none:  return "none"
        }
    }
}
