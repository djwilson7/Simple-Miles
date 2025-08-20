//
//  TripsDAO.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import SQLite3


/// Data Access Object for the `trips` metadata table.
/// All calls are funneled through `Database.shared` (thread-safe via internal queue).
enum TripsDAO {

    // MARK: - Inserts / Updates

    static func insertOrReplace(_ meta: TripMeta) throws {
        try Database.shared.inWrite { db in
            let sql = """
            INSERT OR REPLACE INTO trips (
              id, type, start_ts, end_ts, distance_m, duration_s,
              bbox_min_lat, bbox_min_lon, bbox_max_lat, bbox_max_lon,
              size_bytes, version
            ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?);
            """
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, meta.id)
            sqlite3_bind_int(stmt, 2, Int32(meta.type))
            sqlite3_bind_int64(stmt, 3, meta.startTs)
            sqlite3_bind_int64(stmt, 4, meta.endTs)
            sqlite3_bind_double(stmt, 5, meta.distanceM)
            sqlite3_bind_double(stmt, 6, meta.durationS)
            sqlite3_bind_int(stmt, 7, meta.bboxMinLat)
            sqlite3_bind_int(stmt, 8, meta.bboxMinLon)
            sqlite3_bind_int(stmt, 9, meta.bboxMaxLat)
            sqlite3_bind_int(stmt, 10, meta.bboxMaxLon)
            sqlite3_bind_int64(stmt, 11, meta.sizeBytes)
            sqlite3_bind_int(stmt, 12, Int32(meta.version))
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }
        }
    }

    static func reclassify(id: String, to newType: Int) throws {
        try Database.shared.inWrite { db in
            let sql = "UPDATE trips SET type=? WHERE id=?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            sqlite3_bind_int(stmt, 1, Int32(newType))
            bindText(stmt, 2, id)
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }
        }
    }

    static func delete(id: String) throws {
        try Database.shared.inWrite { db in
            let sql = "DELETE FROM trips WHERE id=?;" // ON DELETE CASCADE removes blobs
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, id)
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }
        }
    }

    // MARK: - Queries

    /// Fetch a page of trips for a type, ordered by start_ts DESC.
    /// - Parameters:
    ///   - type: Trip type raw value.
    ///   - afterTs: If provided, fetch rows with start_ts < afterTs (keyset pagination). If nil, fetch newest page.
    ///   - limit: Page size.
    static func fetchPage(type: Int, afterTs: Int64?, limit: Int) throws -> [TripMeta] {
        return try Database.shared.inRead { db in
            var rows: [TripMeta] = []
            let base = "SELECT id,type,start_ts,end_ts,distance_m,duration_s,bbox_min_lat,bbox_min_lon,bbox_max_lat,bbox_max_lon,size_bytes,version FROM trips WHERE type=?"
            let tail = " ORDER BY start_ts DESC LIMIT ?;"
            let predicate = (afterTs != nil) ? " AND start_ts < ?" : ""
            let sql = base + predicate + tail

            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            var bindIndex: Int32 = 1
            sqlite3_bind_int(stmt, bindIndex, Int32(type)); bindIndex += 1
            if let afterTs {
                sqlite3_bind_int64(stmt, bindIndex, afterTs); bindIndex += 1
            }
            sqlite3_bind_int(stmt, bindIndex, Int32(limit))

            while sqlite3_step(stmt) == SQLITE_ROW {
                rows.append(readTripMetaRow(stmt))
            }
            return rows
        }
    }

    static func fetch(by id: String) throws -> TripMeta? {
        return try Database.shared.inRead { db in
            let sql = "SELECT id,type,start_ts,end_ts,distance_m,duration_s,bbox_min_lat,bbox_min_lon,bbox_max_lat,bbox_max_lon,size_bytes,version FROM trips WHERE id=? LIMIT 1;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_ROW {
                return readTripMetaRow(stmt)
            }
            return nil
        }
    }

    static func fetchTotals(for type: Int) throws -> Totals {
        return try Database.shared.inRead { db in
            let sql = "SELECT COALESCE(SUM(distance_m),0), COALESCE(SUM(duration_s),0), COUNT(*) FROM trips WHERE type=?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            sqlite3_bind_int(stmt, 1, Int32(type))
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                throw DBError.sqlite(message: lastError(db))
            }
            let dist = sqlite3_column_double(stmt, 0)
            let dura = sqlite3_column_double(stmt, 1)
            let count = Int(sqlite3_column_int(stmt, 2))
            return Totals(totalDistanceM: dist, totalDurationS: dura, tripCount: count)
        }
    }

    // MARK: - Row decoding & helpers

    private static func readTripMetaRow(_ stmt: OpaquePointer?) -> TripMeta {
        let id = String(cString: sqlite3_column_text(stmt, 0))
        let type = Int(sqlite3_column_int(stmt, 1))
        let startTs = sqlite3_column_int64(stmt, 2)
        let endTs = sqlite3_column_int64(stmt, 3)
        let distanceM = sqlite3_column_double(stmt, 4)
        let durationS = sqlite3_column_double(stmt, 5)
        let minLat = sqlite3_column_int(stmt, 6)
        let minLon = sqlite3_column_int(stmt, 7)
        let maxLat = sqlite3_column_int(stmt, 8)
        let maxLon = sqlite3_column_int(stmt, 9)
        let sizeBytes = sqlite3_column_int64(stmt, 10)
        let version = Int(sqlite3_column_int(stmt, 11))
        return TripMeta(id: id, type: type, startTs: startTs, endTs: endTs,
                        distanceM: distanceM, durationS: durationS,
                        bboxMinLat: minLat, bboxMinLon: minLon, bboxMaxLat: maxLat, bboxMaxLon: maxLon,
                        sizeBytes: sizeBytes, version: version)
    }

    private static func bindText(_ stmt: OpaquePointer?, _ idx: Int32, _ string: String) {
        sqlite3_bind_text(stmt, idx, string, -1, SQLITE_TRANSIENT)
    }

    private static func lastError(_ db: OpaquePointer) -> String { String(cString: sqlite3_errmsg(db)) }
}

// Required by sqlite3_bind_text when passing Swift-managed strings
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
