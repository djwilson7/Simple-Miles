
//  TripBlobsDAO.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import SQLite3

/// The two blob variants we store per trip.
/// - `raw`: full-fidelity path series (for export/analytics)
/// - `display`: RDP-simplified series for fast map rendering
enum BlobKind: String {
    case raw
    case display
}

/// DAO for reading/writing compressed geometry payloads backed by the `trip_blobs` table.
/// Blobs are opaque to SQLite; we keep `codec` (e.g., "lzfse") and `encoding_version` for decoder choice.
enum TripBlobsDAO {

    // MARK: - Writes

    /// Insert or replace a blob row for a trip.
    static func writeBlob(tripID: String,
                          kind: BlobKind,
                          codec: String,
                          encodingVersion: Int,
                          bytes: Data) throws {
        try Database.shared.inWrite { db in
            let sql = """
            INSERT OR REPLACE INTO trip_blobs (trip_id, kind, codec, encoding_version, bytes)
            VALUES (?,?,?,?,?);
            """
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, tripID)
            bindText(stmt, 2, kind.rawValue)
            bindText(stmt, 3, codec)
            sqlite3_bind_int(stmt, 4, Int32(encodingVersion))
            bytes.withUnsafeBytes { rawBuf in
                let ptr = rawBuf.baseAddress
                sqlite3_bind_blob(stmt, 5, ptr, Int32(bytes.count), SQLITE_TRANSIENT)
            }
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }

            // Update aggregate size on the parent trip for quick stats
            try updateTripSizeBytes(db, tripID: tripID)
        }
    }

    // MARK: - Reads

    /// Read a blob row for a given trip and kind.
    /// - Returns: (codec, encodingVersion, bytes) or nil if missing
    static func readBlob(tripID: String, kind: BlobKind) throws -> (codec: String, encodingVersion: Int, bytes: Data)? {
        return try Database.shared.inRead { db in
            let sql = """
            SELECT codec, encoding_version, bytes
            FROM trip_blobs
            WHERE trip_id=? AND kind=?
            LIMIT 1;
            """
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, tripID)
            bindText(stmt, 2, kind.rawValue)

            if sqlite3_step(stmt) == SQLITE_ROW {
                let codec = String(cString: sqlite3_column_text(stmt, 0))
                let encVer = Int(sqlite3_column_int(stmt, 1))
                let blobPtr = sqlite3_column_blob(stmt, 2)
                let blobSize = Int(sqlite3_column_bytes(stmt, 2))
                let data = Data(bytes: blobPtr!, count: blobSize)
                return (codec, encVer, data)
            }
            return nil
        }
    }

    // MARK: - Deletes

    /// Delete blobs for a trip. If `kind` is nil, deletes both raw & display.
    static func deleteBlobs(tripID: String, kind: BlobKind? = nil) throws {
        try Database.shared.inWrite { db in
            let sql: String
            if kind != nil {
                sql = "DELETE FROM trip_blobs WHERE trip_id=? AND kind=?;"
            } else {
                sql = "DELETE FROM trip_blobs WHERE trip_id=?;"
            }
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, tripID)
            if let kind { bindText(stmt, 2, kind.rawValue) }
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }

            try updateTripSizeBytes(db, tripID: tripID)
        }
    }

    // MARK: - Helpers

    /// Recompute and persist the aggregate blob size for a trip.
    private static func updateTripSizeBytes(_ db: OpaquePointer, tripID: String) throws {
        let sumSQL = "SELECT COALESCE(SUM(length(bytes)),0) FROM trip_blobs WHERE trip_id=?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sumSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        bindText(stmt, 1, tripID)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        let size = sqlite3_column_int64(stmt, 0)

        let upd = "UPDATE trips SET size_bytes=? WHERE id=?;"
        var updStmt: OpaquePointer?
        defer { sqlite3_finalize(updStmt) }
        guard sqlite3_prepare_v2(db, upd, -1, &updStmt, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        sqlite3_bind_int64(updStmt, 1, size)
        bindText(updStmt, 2, tripID)
        guard sqlite3_step(updStmt) == SQLITE_DONE else {
            throw DBError.sqlite(message: lastError(db))
        }
    }

    private static func bindText(_ stmt: OpaquePointer?, _ idx: Int32, _ string: String) {
        sqlite3_bind_text(stmt, idx, string, -1, SQLITE_TRANSIENT)
    }

    private static func lastError(_ db: OpaquePointer) -> String { String(cString: sqlite3_errmsg(db)) }
}

// Required by sqlite3_bind_text/blob when passing Swift-managed memory
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

