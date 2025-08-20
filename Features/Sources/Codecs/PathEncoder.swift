
//  PathEncoder.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import CoreLocation
import Compression

/// Encodes LocationPoint streams and coordinate-only display paths
/// into a compact, compressed binary payload suitable for DB-backed BLOBs.
///
/// Format v1 (little-endian):
/// Header:
///  - magic    : 4 bytes ASCII "SMPT"
///  - version  : u8 (1)
///  - flags    : u8 (bit0=hasSpeed, bit1=hasCourse, bit2=hasTime)
///  - reserved : u8 (0)
///  - count    : u32 (#points)
///  - lat0,lon0: i32 microdegrees
///  - [t0]     : i64 epoch ms       (if hasTime)
///  - [s0]     : u16 cm/s           (if hasSpeed)
///  - [c0]     : u16 centi-degrees  (if hasCourse)
///  - bbox     : i32 minLat, minLon, maxLat, maxLon (microdegrees)
/// Body (then LZFSE-compressed as a whole): for i=1..n-1
///  - Δlat  : ZigZag varint (i32 microdegrees)
///  - Δlon  : ZigZag varint (i32 microdegrees)
///  - [Δt]  : unsigned varint (i64 ms)     (if hasTime)
///  - [Δs]  : ZigZag varint (i32 cm/s)     (if hasSpeed)
///  - [Δc]  : ZigZag varint (i32 centi-deg) shortest angular delta (±18000) (if hasCourse)
/// Footer: none (DB layer may add checksum if desired)
public enum PathEncoder {

    // MARK: - Public API

    /// Encode full-fidelity RAW points (coord + timestamp + speed + course)
    public static func encodeRaw(points: [LocationPoint]) throws -> Data {
        guard !points.isEmpty else { return Data() }
        let hasSpeed = true, hasCourse = true, hasTime = true

        // Quantize anchors
        let first = points[0]
        let lat0 = toMicro(first.coordinate.latitude)
        let lon0 = toMicro(first.coordinate.longitude)
        let t0   = toMillis(first.timestamp)
        let s0   = toCentimetersPerSecond(first.speed)
        let c0   = toCentiDegrees(first.course)

        // BBox (compute from coords)
        let bbox = bboxFrom(points.map { $0.coordinate })

        // Body writer (uncompressed varint stream)
        var body = VarintWriter()
        var prevLat = lat0
        var prevLon = lon0
        var prevT   = t0
        var prevS   = s0
        var prevC   = c0

        for p in points.dropFirst() {
            let lat = toMicro(p.coordinate.latitude)
            let lon = toMicro(p.coordinate.longitude)
            let Δlat = lat &- prevLat
            let Δlon = lon &- prevLon
            body.writeZigZag(Int64(Δlat))
            body.writeZigZag(Int64(Δlon))
            if hasTime {
                let t = toMillis(p.timestamp)
                let Δt = t &- prevT // non-negative
                body.writeUnsigned(UInt64(Δt))
                prevT = t
            }
            if hasSpeed {
                let s = toCentimetersPerSecond(p.speed)
                let Δs = Int64(s) - Int64(prevS)
                body.writeZigZag(Δs)
                prevS = s
            }
            if hasCourse {
                let c = toCentiDegrees(p.course)
                let Δc = shortestAngularDeltaCenti(prev: Int(prevC), next: Int(c))
                body.writeZigZag(Int64(Δc))
                prevC = c
            }
            prevLat = lat
            prevLon = lon
        }

        // Header (uncompressed)
        var header = Data()
        header.append(contentsOf: [0x53, 0x4D, 0x50, 0x54]) // "SMPT"
        header.append(1) // version
        var flags: UInt8 = 0
        if hasSpeed { flags |= 0b00000001 }
        if hasCourse { flags |= 0b00000010 }
        if hasTime { flags |= 0b00000100 }
        header.append(flags)
        header.append(0) // reserved
        header.appendUInt32(UInt32(points.count))
        header.appendInt32(lat0)
        header.appendInt32(lon0)
        if hasTime { header.appendInt64(t0) }
        if hasSpeed { header.appendUInt16(UInt16(clamping: Int(s0))) }
        if hasCourse { header.appendUInt16(UInt16(clamping: Int(c0))) }
        header.appendInt32(bbox.minLat)
        header.appendInt32(bbox.minLon)
        header.appendInt32(bbox.maxLat)
        header.appendInt32(bbox.maxLon)

        // Compress body with LZFSE
        let compressedBody = compressLZFSE(body.data)

        // Payload = header + compressed body
        var payload = Data(capacity: header.count + compressedBody.count)
        payload.append(header)
        payload.append(compressedBody)
        return payload
    }

    /// Encode DISPLAY path (coordinates only). Timestamps/speed/course omitted.
    public static func encodeDisplay(coords: [CLLocationCoordinate2D]) throws -> Data {
        guard !coords.isEmpty else { return Data() }
        let hasSpeed = false, hasCourse = false, hasTime = false

        let first = coords[0]
        let lat0 = toMicro(first.latitude)
        let lon0 = toMicro(first.longitude)
        let bbox = bboxFrom(coords)

        var body = VarintWriter()
        var prevLat = lat0
        var prevLon = lon0
        for c in coords.dropFirst() {
            let lat = toMicro(c.latitude)
            let lon = toMicro(c.longitude)
            body.writeZigZag(Int64(lat &- prevLat))
            body.writeZigZag(Int64(lon &- prevLon))
            prevLat = lat
            prevLon = lon
        }

        var header = Data()
        header.append(contentsOf: [0x53, 0x4D, 0x50, 0x54]) // "SMPT"
        header.append(1) // version
        var flags: UInt8 = 0
        if hasSpeed { flags |= 0b00000001 }
        if hasCourse { flags |= 0b00000010 }
        if hasTime { flags |= 0b00000100 }
        header.append(flags)
        header.append(0)
        header.appendUInt32(UInt32(coords.count))
        header.appendInt32(lat0)
        header.appendInt32(lon0)
        // no t0/s0/c0 for display
        header.appendInt32(bbox.minLat)
        header.appendInt32(bbox.minLon)
        header.appendInt32(bbox.maxLat)
        header.appendInt32(bbox.maxLon)

        let compressedBody = compressLZFSE(body.data)
        var payload = Data(capacity: header.count + compressedBody.count)
        payload.append(header)
        payload.append(compressedBody)
        return payload
    }

    // MARK: - Quantization helpers

    @inline(__always)
    private static func toMicro(_ degrees: CLLocationDegrees) -> Int32 {
        Int32((degrees * 1_000_000.0).rounded())
    }

    @inline(__always)
    private static func toMillis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    @inline(__always)
    private static func toCentimetersPerSecond(_ speed: CLLocationSpeed) -> UInt16 {
        // clamp to u16
        let cmps = Int((speed * 100.0).rounded())
        return UInt16(clamping: cmps)
    }

    @inline(__always)
    private static func toCentiDegrees(_ course: CLLocationDirection) -> UInt16 {
        let centi = Int((course * 100.0).rounded()) % 36000
        return UInt16((centi + 36000) % 36000)
    }

    private static func shortestAngularDeltaCenti(prev: Int, next: Int) -> Int16 {
        var d = next - prev
        d = (d + 18000) % 36000 - 18000
        return Int16(d)
    }

    private static func bboxFrom(_ coords: [CLLocationCoordinate2D]) -> (minLat: Int32, minLon: Int32, maxLat: Int32, maxLon: Int32) {
        guard let f = coords.first else { return (0,0,0,0) }
        var minLat = f.latitude, maxLat = f.latitude
        var minLon = f.longitude, maxLon = f.longitude
        for c in coords.dropFirst() {
            if c.latitude < minLat { minLat = c.latitude }
            if c.latitude > maxLat { maxLat = c.latitude }
            if c.longitude < minLon { minLon = c.longitude }
            if c.longitude > maxLon { maxLon = c.longitude }
        }
        return (toMicro(minLat), toMicro(minLon), toMicro(maxLat), toMicro(maxLon))
    }

    // MARK: - Compression

    private static func compressLZFSE(_ data: Data) -> Data {
        guard !data.isEmpty else { return data }
        return data.withUnsafeBytes { (srcBuf: UnsafeRawBufferPointer) -> Data in
            let src = srcBuf.bindMemory(to: UInt8.self).baseAddress!
            let srcSize = data.count
            // Heuristic: LZFSE worst-case slightly expands; allocate srcSize + 8KB headroom
            let dstCapacity = srcSize + 8192
            let dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstPtr.deallocate() }
            let written = compression_encode_buffer(dstPtr, dstCapacity, src, srcSize, nil, COMPRESSION_LZFSE)
            if written == 0 { return data } // fallback to uncompressed if encode failed
            return Data(bytes: dstPtr, count: written)
        }
    }
}

// MARK: - Varint writer & Data append helpers

fileprivate struct VarintWriter {
    private(set) var data = Data()

    mutating func writeUnsigned(_ value: UInt64) {
        var v = value
        while v >= 0x80 {
            data.append(UInt8((v & 0x7F) | 0x80))
            v >>= 7
        }
        data.append(UInt8(v & 0x7F))
    }

    mutating func writeZigZag(_ signed: Int64) {
        let u = UInt64(bitPattern: (signed << 1) ^ (signed >> 63))
        writeUnsigned(u)
    }
}

fileprivate extension Data {
    mutating func appendUInt32(_ v: UInt32) {
        var x = v.littleEndian
        Swift.withUnsafeBytes(of: &x) { append($0.bindMemory(to: UInt8.self)) }
    }
    mutating func appendInt32(_ v: Int32) {
        var x = v.littleEndian
        Swift.withUnsafeBytes(of: &x) { append($0.bindMemory(to: UInt8.self)) }
    }
    mutating func appendInt64(_ v: Int64) {
        var x = v.littleEndian
        Swift.withUnsafeBytes(of: &x) { append($0.bindMemory(to: UInt8.self)) }
    }
    mutating func appendUInt16(_ v: UInt16) {
        var x = v.littleEndian
        Swift.withUnsafeBytes(of: &x) { append($0.bindMemory(to: UInt8.self)) }
    }
}
