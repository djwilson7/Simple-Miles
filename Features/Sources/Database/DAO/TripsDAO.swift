//
//  TripsDAO.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import SQLite3

private func currentUnixTime() -> Int64 { Int64(Date().timeIntervalSince1970) }

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

    /// Update-only: modifies an existing trips row by id. Fails if the row does not exist.
    static func update(_ meta: TripMeta) throws {
        try Database.shared.inWrite { db in
            let sql = """
            UPDATE trips SET
              type=?,
              start_ts=?,
              end_ts=?,
              distance_m=?,
              duration_s=?,
              bbox_min_lat=?,
              bbox_min_lon=?,
              bbox_max_lat=?,
              bbox_max_lon=?,
              size_bytes=?,
              version=?
            WHERE id=?;
            """
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            sqlite3_bind_int(stmt, 1, Int32(meta.type))
            sqlite3_bind_int64(stmt, 2, meta.startTs)
            sqlite3_bind_int64(stmt, 3, meta.endTs)
            sqlite3_bind_double(stmt, 4, meta.distanceM)
            sqlite3_bind_double(stmt, 5, meta.durationS)
            sqlite3_bind_int(stmt, 6, meta.bboxMinLat)
            sqlite3_bind_int(stmt, 7, meta.bboxMinLon)
            sqlite3_bind_int(stmt, 8, meta.bboxMaxLat)
            sqlite3_bind_int(stmt, 9, meta.bboxMaxLon)
            sqlite3_bind_int64(stmt, 10, meta.sizeBytes)
            sqlite3_bind_int(stmt, 11, Int32(meta.version))
            bindText(stmt, 12, meta.id)
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }
            // Optional: ensure a row was actually updated
            if sqlite3_changes(db) == 0 {
                throw DBError.sqlite(message: "No rows updated for id=\(meta.id)")
            }
        }
    }

    static func reclassify(id: String, to newType: Int) throws {
        try Database.shared.inWrite { db in
            // 1) Fetch current type to detect transitions
            var oldType: Int32 = -1
            do {
                let sel = "SELECT type FROM trips WHERE id=? LIMIT 1;"
                var s: OpaquePointer?
                defer { sqlite3_finalize(s) }
                guard sqlite3_prepare_v2(db, sel, -1, &s, nil) == SQLITE_OK else {
                    throw DBError.sqlite(message: lastError(db))
                }
                bindText(s, 1, id)
                if sqlite3_step(s) == SQLITE_ROW {
                    oldType = sqlite3_column_int(s, 0)
                } else {
                    throw DBError.sqlite(message: "No trip found for id=\(id)")
                }
            }

            // 2) Update trips.type
            do {
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

            // 3) Trash table bookkeeping
            let wasTrash = (oldType == Int32(TripType.trash.dbValue))
            let willTrash = (newType == TripType.trash.dbValue)
            if !wasTrash && willTrash {
                // moved into trash → record timestamp
                let ins = "INSERT OR REPLACE INTO trash (trip_id, deleted_at) VALUES (?,?);"
                var t: OpaquePointer?
                defer { sqlite3_finalize(t) }
                guard sqlite3_prepare_v2(db, ins, -1, &t, nil) == SQLITE_OK else {
                    throw DBError.sqlite(message: lastError(db))
                }
                bindText(t, 1, id)
                sqlite3_bind_int64(t, 2, currentUnixTime())
                guard sqlite3_step(t) == SQLITE_DONE else {
                    throw DBError.sqlite(message: lastError(db))
                }
            } else if wasTrash && !willTrash {
                // restored from trash → remove marker
                let del = "DELETE FROM trash WHERE trip_id=?;"
                var t: OpaquePointer?
                defer { sqlite3_finalize(t) }
                guard sqlite3_prepare_v2(db, del, -1, &t, nil) == SQLITE_OK else {
                    throw DBError.sqlite(message: lastError(db))
                }
                bindText(t, 1, id)
                guard sqlite3_step(t) == SQLITE_DONE else {
                    throw DBError.sqlite(message: lastError(db))
                }
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

    static func fetchMilesData(for type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> (typeMeters: Double, totalMeters: Double) {
        return try Database.shared.inRead { db in
            var datePredicate = ""
            if from != nil {
                datePredicate += " AND start_ts >= ?"
            }
            if to != nil {
                datePredicate += " AND start_ts <= ?"
            }

            let bindDateParams: (OpaquePointer?, inout Int32) -> Void = { stmt, index in
                if let from = from {
                    sqlite3_bind_int64(stmt, index, from)
                    index += 1
                }
                if let to = to {
                    sqlite3_bind_int64(stmt, index, to)
                    index += 1
                }
            }

            // Query 1: Sum of distance_m for the given type
            let sqlType = "SELECT COALESCE(SUM(distance_m),0) FROM trips WHERE type=?" + datePredicate + ";"
            var stmtType: OpaquePointer?
            defer { sqlite3_finalize(stmtType) }
            guard sqlite3_prepare_v2(db, sqlType, -1, &stmtType, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            var bindIndex: Int32 = 1
            sqlite3_bind_int(stmtType, bindIndex, Int32(type.dbValue))
            bindIndex += 1
            bindDateParams(stmtType, &bindIndex)
            guard sqlite3_step(stmtType) == SQLITE_ROW else {
                throw DBError.sqlite(message: lastError(db))
            }
            let tripTypeMeters = sqlite3_column_double(stmtType, 0)
            Log("Trip Type Meters: \(tripTypeMeters)")
            // Query 2: Sum of distance_m for trips where type != unclassified and type != trash
            let sqlTotal = "SELECT COALESCE(SUM(distance_m),0) FROM trips WHERE type!=? AND type!=?" + datePredicate + ";"
            var stmtTotal: OpaquePointer?
            defer { sqlite3_finalize(stmtTotal) }
            guard sqlite3_prepare_v2(db, sqlTotal, -1, &stmtTotal, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindIndex = 1
            sqlite3_bind_int(stmtTotal, bindIndex, Int32(TripType.unsorted.dbValue))
            bindIndex += 1
            sqlite3_bind_int(stmtTotal, bindIndex, Int32(TripType.trash.dbValue))
            bindIndex += 1
            bindDateParams(stmtTotal, &bindIndex)
            guard sqlite3_step(stmtTotal) == SQLITE_ROW else {
                throw DBError.sqlite(message: lastError(db))
            }
            let allMeters = sqlite3_column_double(stmtTotal, 0)
            Log("All Meters: \(allMeters)")

            return (typeMeters: tripTypeMeters, totalMeters: allMeters)
        }
    }

    /// Count trips for a given type.
    static func count(for type: Int) throws -> Int {
        return try Database.shared.inRead { db in
            let sql = "SELECT COUNT(*) FROM trips WHERE type=?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }
            sqlite3_bind_int(stmt, 1, Int32(type))
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                throw DBError.sqlite(message: lastError(db))
            }
            return Int(sqlite3_column_int64(stmt, 0))
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

