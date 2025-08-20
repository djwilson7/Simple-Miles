//
//  PathCompressor.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//


//
//  PathCompressor.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import Compression

/// Thin wrapper around Apple's Compression framework for path payloads.
///
/// We default to LZFSE for on-disk blobs (great ratio + fast), and keep LZ4
/// available for very fast decode scenarios if you ever want to switch.
public enum PathCompressor {

    public enum Codec: String { case lzfse, lz4, none }

    // MARK: - One-shot APIs

    /// Compress a buffer with the requested codec.
    /// - Parameters:
    ///   - data: Input bytes
    ///   - codec: .lzfse (default), .lz4, or .none (passthrough)
    /// - Returns: Compressed bytes (or original if .none or failure)
    public static func compress(_ data: Data, codec: Codec = .lzfse) -> Data {
        switch codec {
        case .none: return data
        case .lzfse: return transcode(data, operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_LZFSE)
        case .lz4:   return transcode(data, operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_LZ4)
        }
    }

    /// Decompress a buffer with the requested codec.
    /// - Parameters:
    ///   - data: Compressed bytes
    ///   - codec: Codec used during compression
    /// - Returns: Decompressed bytes (or original if .none or failure)
    public static func decompress(_ data: Data, codec: Codec) -> Data {
        switch codec {
        case .none: return data
        case .lzfse: return transcode(data, operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_LZFSE)
        case .lz4:   return transcode(data, operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_LZ4)
        }
    }

    // MARK: - Streaming engine (handles unknown output sizes safely)

    private static func transcode(_ input: Data, operation: compression_stream_operation, algorithm: compression_algorithm) -> Data {
        guard !input.isEmpty else { return input }

        switch operation {
        case COMPRESSION_STREAM_ENCODE:
            // Encode with compression_encode_buffer, growing dst if needed
            return input.withUnsafeBytes { (srcBuf: UnsafeRawBufferPointer) -> Data in
                guard let src = srcBuf.bindMemory(to: UInt8.self).baseAddress else { return input }
                var dstCapacity = max(1024, input.count + 8192) // headroom for LZFSE
                while dstCapacity < Int.max / 2 {
                    let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                    defer { dst.deallocate() }
                    let written = compression_encode_buffer(dst, dstCapacity, src, input.count, nil, algorithm)
                    if written > 0 {
                        return Data(bytes: dst, count: written)
                    }
                    dstCapacity *= 2 // grow and retry
                }
                return input // fall back
            }

        case COMPRESSION_STREAM_DECODE:
            // Decode with compression_decode_buffer, doubling dst until it fits
            return input.withUnsafeBytes { (srcBuf: UnsafeRawBufferPointer) -> Data in
                guard let src = srcBuf.bindMemory(to: UInt8.self).baseAddress else { return input }
                var dstCapacity = max(4096, input.count * 4)
                while dstCapacity <= 64 * 1024 * 1024 { // 64MB safety cap
                    let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                    defer { dst.deallocate() }
                    let written = compression_decode_buffer(dst, dstCapacity, src, input.count, nil, algorithm)
                    if written > 0 {
                        return Data(bytes: dst, count: written)
                    }
                    dstCapacity *= 2
                }
                return Data() // signal failure; caller falls back appropriately
            }

        default:
            return input
        }
    }
}
