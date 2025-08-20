//
//  PathDecoder.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import CoreLocation
import Compression

/// Errors that can occur while decoding a path payload.
enum PathDecodeError: Error, LocalizedError {
    case empty
    case badMagic
    case unsupportedVersion(Int)
    case unsupportedCodec(String)
    case truncated
    case corrupt

    var errorDescription: String? {
        switch self {
        case .empty: return "Empty payload"
        case .badMagic: return "Bad payload magic header"
        case .unsupportedVersion(let v): return "Unsupported payload version: \(v)"
        case .unsupportedCodec(let c): return "Unsupported codec: \(c)"
        case .truncated: return "Payload truncated"
        case .corrupt: return "Payload corrupt"
        }
    }
}

/// Mirror of PathEncoder; decodes RAW (full LocationPoint) and DISPLAY (coords only) payloads.
public enum PathDecoder {

    // MARK: - Public API expected by TripStoreSQLite.Codecs

    /// Decode a DISPLAY blob to coordinates for rendering.
    public static func decodeDisplay(_ bytes: Data, codec: String, version: Int) throws -> [CLLocationCoordinate2D] {
        let h = try Header(bytes)
        guard version == h.version else { throw PathDecodeError.unsupportedVersion(version) }
        let body = try decompressBody(bytes, headerSize: h.headerSize, codec: codec)
        var r = VarintReader(body)

        // Reconstruct coords
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(Int(h.count))
        var lat = h.lat0
        var lon = h.lon0
        coords.append(CLLocationCoordinate2D(latitude: toDegrees(lat), longitude: toDegrees(lon)))
        if h.count > 1 {
            for _ in 1..<h.count {
                lat &+= Int32(truncatingIfNeeded: r.readZigZag())
                lon &+= Int32(truncatingIfNeeded: r.readZigZag())
                coords.append(CLLocationCoordinate2D(latitude: toDegrees(lat), longitude: toDegrees(lon)))
            }
        }
        return coords
    }

    /// Decode a RAW blob to full LocationPoint series (coord + timestamp + speed + course).
    public static func decodeRaw(_ bytes: Data, codec: String, version: Int) throws -> [LocationPoint] {
        let h = try Header(bytes)
        guard version == h.version else { throw PathDecodeError.unsupportedVersion(version) }
        let body = try decompressBody(bytes, headerSize: h.headerSize, codec: codec)
        var r = VarintReader(body)

        // Sanity flags
        guard h.hasTime else { throw PathDecodeError.corrupt }

        var points: [LocationPoint] = []
        points.reserveCapacity(Int(h.count))

        // Anchors
        var lat = h.lat0
        var lon = h.lon0
        var t   = h.t0 ?? 0
        var s   = Int(h.s0 ?? 0) // cm/s
        var c   = Int(h.c0 ?? 0) // centi-deg 0..35999

        // First point from anchors
        let firstCoord = CLLocationCoordinate2D(latitude: toDegrees(lat), longitude: toDegrees(lon))
        let firstLoc = CLLocation(
            coordinate: firstCoord,
            altitude: 0,                               // default
            horizontalAccuracy: kCLLocationAccuracyNearestTenMeters, // default placeholder
            verticalAccuracy: kCLLocationAccuracyNearestTenMeters,   // default placeholder
            course: Double(c) / 100.0,
            speed: Double(s) / 100.0,
            timestamp: Date(timeIntervalSince1970: TimeInterval(t) / 1000.0)
        )
        points.append(LocationPoint(firstLoc))

        // Subsequent points
        if h.count > 1 {
            for _ in 1..<h.count {
                lat &+= Int32(truncatingIfNeeded: r.readZigZag())
                lon &+= Int32(truncatingIfNeeded: r.readZigZag())
                if h.hasTime { t &+= Int64(r.readUnsigned()) }
                if h.hasSpeed { s &+= Int(r.readZigZag()) }
                if h.hasCourse {
                    let delta = Int(r.readZigZag())
                    c = wrapAngleCenti(c + delta)
                }
                let coord = CLLocationCoordinate2D(latitude: toDegrees(lat), longitude: toDegrees(lon))
                let loc = CLLocation(
                    coordinate: coord,
                    altitude: 0,                               // default
                    horizontalAccuracy: kCLLocationAccuracyNearestTenMeters, // default placeholder
                    verticalAccuracy: kCLLocationAccuracyNearestTenMeters,   // default placeholder
                    course: Double(c) / 100.0,
                    speed: Double(s) / 100.0,
                    timestamp: Date(timeIntervalSince1970: TimeInterval(t) / 1000.0)
                )
                points.append(LocationPoint(loc))
            }
        }
        return points
    }

    // MARK: - Internals

    private struct Header {
        let version: Int
        let hasSpeed: Bool
        let hasCourse: Bool
        let hasTime: Bool
        let count: Int
        let lat0: Int32
        let lon0: Int32
        let t0: Int64?
        let s0: UInt16?
        let c0: UInt16?
        let bbox: (minLat: Int32, minLon: Int32, maxLat: Int32, maxLon: Int32)
        let headerSize: Int

        init(_ bytes: Data) throws {
            if bytes.isEmpty { throw PathDecodeError.empty }
            var offset = 0
            func need(_ n: Int) throws {
                if offset + n > bytes.count { throw PathDecodeError.truncated }
            }
            try need(4)
            // Magic "SMPT"
            if !(bytes[offset] == 0x53 && bytes[offset+1] == 0x4D && bytes[offset+2] == 0x50 && bytes[offset+3] == 0x54) {
                throw PathDecodeError.badMagic
            }
            offset += 4
            try need(3)
            let ver = Int(bytes[offset]); offset += 1
            let flags = bytes[offset]; offset += 1
            offset += 1 // reserved
            guard ver == 1 else { throw PathDecodeError.unsupportedVersion(ver) }
            self.version = ver
            self.hasSpeed = (flags & 0b00000001) != 0
            self.hasCourse = (flags & 0b00000010) != 0
            self.hasTime = (flags & 0b00000100) != 0

            try need(4 + 4 + 4)
            let countU32 = bytes.readUInt32LE(at: offset); offset += 4
            self.count = Int(countU32)
            self.lat0 = bytes.readInt32LE(at: offset); offset += 4
            self.lon0 = bytes.readInt32LE(at: offset); offset += 4

            if hasTime { try need(8); self.t0 = bytes.readInt64LE(at: offset); offset += 8 } else { self.t0 = nil }
            if hasSpeed { try need(2); self.s0 = bytes.readUInt16LE(at: offset); offset += 2 } else { self.s0 = nil }
            if hasCourse { try need(2); self.c0 = bytes.readUInt16LE(at: offset); offset += 2 } else { self.c0 = nil }

            try need(16)
            let minLat = bytes.readInt32LE(at: offset); offset += 4
            let minLon = bytes.readInt32LE(at: offset); offset += 4
            let maxLat = bytes.readInt32LE(at: offset); offset += 4
            let maxLon = bytes.readInt32LE(at: offset); offset += 4
            self.bbox = (minLat, minLon, maxLat, maxLon)

            self.headerSize = offset
        }
    }

    private static func decompressBody(_ bytes: Data, headerSize: Int, codec: String) throws -> Data {
        if headerSize == bytes.count { return Data() }
        let comp = bytes.suffix(from: headerSize)
        switch codec.lowercased() {
        case "lzfse":
            return decompress(comp, algorithm: COMPRESSION_LZFSE)
        case "lz4":
            return decompress(comp, algorithm: COMPRESSION_LZ4)
        case "none", "raw":
            return Data(comp)
        default:
            throw PathDecodeError.unsupportedCodec(codec)
        }
    }

    private static func decompress(_ data: Data, algorithm: compression_algorithm) -> Data {
        guard !data.isEmpty else { return data }
        // Heuristic: start with 4x buffer and grow if needed.
        var dstCapacity = max(1024, data.count * 4)
        while true {
            let out = Data(count: dstCapacity)
            let result: Data = out.withUnsafeBytes { outBuf in
                var outData = out
                return data.withUnsafeBytes { inBuf in
                    let dst = UnsafeMutablePointer<UInt8>(mutating: outBuf.bindMemory(to: UInt8.self).baseAddress!)
                    let src = inBuf.bindMemory(to: UInt8.self).baseAddress!
                    let written = compression_decode_buffer(dst, dstCapacity, src, data.count, nil, algorithm)
                    if written == 0 { return Data() }
                    outData.count = written
                    return outData
                }
            }
            if !result.isEmpty { return result }
            // If failed, double capacity and retry
            dstCapacity *= 2
            if dstCapacity > 64 * 1024 * 1024 { // 64MB cap safety
                return Data()
            }
        }
    }

    @inline(__always)
    private static func toDegrees(_ micro: Int32) -> CLLocationDegrees {
        return CLLocationDegrees(micro) / 1_000_000.0
    }

    @inline(__always)
    private static func wrapAngleCenti(_ value: Int) -> Int {
        var v = value % 36000
        if v < 0 { v += 36000 }
        return v
    }
}

// MARK: - Varint reader and Data helpers

fileprivate struct VarintReader {
    private let bytes: [UInt8]
    private var index: Int = 0

    init(_ data: Data) {
        self.bytes = Array(data)
        self.index = 0
    }

    mutating func readUnsigned() -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while index < bytes.count {
            let b = UInt64(bytes[index]); index += 1
            result |= (b & 0x7F) << shift
            if (b & 0x80) == 0 { break }
            shift += 7
        }
        return result
    }

    mutating func readZigZag() -> Int64 {
        let u = readUnsigned()
        // Decode without overflow: if LSB is 0 => positive; else => negative
        if (u & 1) == 0 {
            return Int64(u >> 1)
        } else {
            // -( (u >> 1) + 1 ) is safe and avoids two's complement edge-case overflow
            return -Int64((u >> 1) + 1)
        }
    }
}

fileprivate extension Data {
    @inline(__always)
    func readUInt16LE(at offset: Int) -> UInt16 {
        precondition(offset >= 0 && offset + 2 <= count, "readUInt16LE out of bounds")
        let b0 = UInt16(self[offset])
        let b1 = UInt16(self[offset + 1])
        return b0 | (b1 << 8)
    }

    @inline(__always)
    func readInt32LE(at offset: Int) -> Int32 {
        precondition(offset >= 0 && offset + 4 <= count, "readInt32LE out of bounds")
        let u: UInt32 = readUInt32LE(at: offset)
        return Int32(bitPattern: u)
    }

    @inline(__always)
    func readUInt32LE(at offset: Int) -> UInt32 {
        precondition(offset >= 0 && offset + 4 <= count, "readUInt32LE out of bounds")
        let b0 = UInt32(self[offset])
        let b1 = UInt32(self[offset + 1]) << 8
        let b2 = UInt32(self[offset + 2]) << 16
        let b3 = UInt32(self[offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }

    @inline(__always)
    func readInt64LE(at offset: Int) -> Int64 {
        precondition(offset >= 0 && offset + 8 <= count, "readInt64LE out of bounds")
        let b0 = UInt64(self[offset])
        let b1 = UInt64(self[offset + 1]) << 8
        let b2 = UInt64(self[offset + 2]) << 16
        let b3 = UInt64(self[offset + 3]) << 24
        let b4 = UInt64(self[offset + 4]) << 32
        let b5 = UInt64(self[offset + 5]) << 40
        let b6 = UInt64(self[offset + 6]) << 48
        let b7 = UInt64(self[offset + 7]) << 56
        let u = b0 | b1 | b2 | b3 | b4 | b5 | b6 | b7
        return Int64(bitPattern: u)
    }
}
