import Foundation
import CoreLocation
import Compression

public enum PathEncoder {
    public static func encodeDisplay(coords: [CLLocationCoordinate2D]) throws -> Data {
        guard !coords.isEmpty else { return Data() }

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
        header.append(contentsOf: [0x53, 0x4D, 0x50, 0x54])
        header.append(1)
        let flags: UInt8 = 0
        header.append(flags)
        header.append(0)
        header.appendUInt32(UInt32(coords.count))
        header.appendInt32(lat0)
        header.appendInt32(lon0)
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

    private static func compressLZFSE(_ data: Data) -> Data {
        guard !data.isEmpty else { return data }
        return data.withUnsafeBytes { (srcBuf: UnsafeRawBufferPointer) -> Data in
            let src = srcBuf.bindMemory(to: UInt8.self).baseAddress!
            let srcSize = data.count
            let dstCapacity = srcSize + 8192
            let dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstPtr.deallocate() }
            let written = compression_encode_buffer(dstPtr, dstCapacity, src, srcSize, nil, COMPRESSION_LZFSE)
            if written == 0 { return data }
            return Data(bytes: dstPtr, count: written)
        }
    }
}

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
