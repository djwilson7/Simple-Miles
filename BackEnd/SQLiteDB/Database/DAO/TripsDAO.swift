import Foundation
import SQLite3

private func currentUnixTime() -> Int64 { Int64(Date().timeIntervalSince1970) }

enum TripsDAO {

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
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
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
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
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
            if sqlite3_changes(db) == 0 {
                throw DBError.sqlite(
                    message: "No rows updated for id=\(meta.id)"
                )
            }
        }
    }

    static func reclassify(id: String, to newType: Int) throws {
        try Database.shared.inWrite { db in
            var oldType: Int32 = -1
            do {
                let sel = "SELECT type FROM trips WHERE id=? LIMIT 1;"
                var s: OpaquePointer?
                defer { sqlite3_finalize(s) }
                guard sqlite3_prepare_v2(db, sel, -1, &s, nil) == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                bindText(s, 1, id)
                if sqlite3_step(s) == SQLITE_ROW {
                    oldType = sqlite3_column_int(s, 0)
                } else {
                    throw DBError.sqlite(message: "No trip found for id=\(id)")
                }
            }

            do {
                let sql = "UPDATE trips SET type=? WHERE id=?;"
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                sqlite3_bind_int(stmt, 1, Int32(newType))
                bindText(stmt, 2, id)
                guard sqlite3_step(stmt) == SQLITE_DONE else {
                    throw DBError.sqlite(message: lastError(db))
                }
            }

            let wasTrash = (oldType == Int32(TripType.trash.dbValue))
            let willTrash = (newType == TripType.trash.dbValue)
            if !wasTrash && willTrash {
                let ins =
                    "INSERT OR REPLACE INTO trash (trip_id, deleted_at) VALUES (?,?);"
                var t: OpaquePointer?
                defer { sqlite3_finalize(t) }
                guard sqlite3_prepare_v2(db, ins, -1, &t, nil) == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                bindText(t, 1, id)
                sqlite3_bind_int64(t, 2, currentUnixTime())
                guard sqlite3_step(t) == SQLITE_DONE else {
                    throw DBError.sqlite(message: lastError(db))
                }
            } else if wasTrash && !willTrash {
                let del = "DELETE FROM trash WHERE trip_id=?;"
                var t: OpaquePointer?
                defer { sqlite3_finalize(t) }
                guard sqlite3_prepare_v2(db, del, -1, &t, nil) == SQLITE_OK
                else {
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
            let sql = "DELETE FROM trips WHERE id=?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
                throw DBError.sqlite(message: lastError(db))
            }
            bindText(stmt, 1, id)
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.sqlite(message: lastError(db))
            }
        }
    }

    static func fetchPage(type: Int, afterTs: Int64?, limit: Int) throws
        -> [TripMeta]
    {
        return try Database.shared.inRead { db in
            var rows: [TripMeta] = []
            let base =
                "SELECT id,type,start_ts,end_ts,distance_m,duration_s,bbox_min_lat,bbox_min_lon,bbox_max_lat,bbox_max_lon,size_bytes,version FROM trips WHERE type=?"
            let tail = " ORDER BY start_ts DESC LIMIT ?;"
            let predicate = (afterTs != nil) ? " AND start_ts < ?" : ""
            let sql = base + predicate + tail

            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
                throw DBError.sqlite(message: lastError(db))
            }
            var bindIndex: Int32 = 1
            sqlite3_bind_int(stmt, bindIndex, Int32(type))
            bindIndex += 1
            if let afterTs {
                sqlite3_bind_int64(stmt, bindIndex, afterTs)
                bindIndex += 1
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
            let sql =
                "SELECT id,type,start_ts,end_ts,distance_m,duration_s,bbox_min_lat,bbox_min_lon,bbox_max_lat,bbox_max_lon,size_bytes,version FROM trips WHERE id=? LIMIT 1;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
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
            let sql =
                "SELECT COALESCE(SUM(distance_m),0), COALESCE(SUM(duration_s),0), COUNT(*) FROM trips WHERE type=?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
                throw DBError.sqlite(message: lastError(db))
            }
            sqlite3_bind_int(stmt, 1, Int32(type))
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                throw DBError.sqlite(message: lastError(db))
            }
            let dist = sqlite3_column_double(stmt, 0)
            let dura = sqlite3_column_double(stmt, 1)
            let count = Int(sqlite3_column_int(stmt, 2))
            return Totals(
                totalDistanceM: dist,
                totalDurationS: dura,
                tripCount: count
            )
        }
    }

    static func fetchBreakdownData(
        for type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawBreakdownData {
        return try Database.shared.inRead { db in
            let typeMeters = try sumDistanceMeters(
                for: type,
                from: from,
                to: to,
                in: db
            )
            let totalMeters = try sumDistanceMetersAllExcludingUnsortedTrash(
                from: from,
                to: to,
                in: db
            )
            let typeCount = try countTrips(
                for: type,
                from: from,
                to: to,
                in: db
            )
            let totalCount = try countTripsAllExcludingUnsortedTrash(
                from: from,
                to: to,
                in: db
            )
            let typeDuration = try sumDurationSeconds(
                for: type,
                from: from,
                to: to,
                in: db
            )
            let totalDuration = try sumDurationSecondsAllExcludingUnsortedTrash(
                from: from,
                to: to,
                in: db
            )
            return RawBreakdownData(
                typeMeters: typeMeters,
                totalMeters: totalMeters,
                typeCount: typeCount,
                totalCount: totalCount,
                typeDurationSecs: typeDuration,
                totalDurationSecs: totalDuration
            )
        }
    }

    static func fetchDOWMeters(
        for type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawDOWData {
        return try Database.shared.inRead { db in
            var buckets = Array(repeating: 0.0, count: 7)

            let sql = """
                SELECT
                  CAST(strftime('%w', datetime(start_ts / 1000, 'unixepoch', 'localtime')) AS INTEGER) AS dow,
                  COALESCE(SUM(distance_m), 0.0) AS meters
                FROM trips
                WHERE type = ?
                \(buildDatePredicate(from: from, to: to))
                GROUP BY dow;
                """

            var s: OpaquePointer?
            defer { sqlite3_finalize(s) }
            guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }

            var i: Int32 = 1
            sqlite3_bind_int(s, i, Int32(type.dbValue))
            i += 1
            bindDateParams(s, &i, from: from, to: to)

            while sqlite3_step(s) == SQLITE_ROW {
                let dow = Int(sqlite3_column_int(s, 0))  
                let meters = sqlite3_column_double(s, 1)
                if (0...6).contains(dow) { buckets[dow] = meters }
            }

            return RawDOWData(meters: buckets)
        }
    }

    static func fetchStartHourHistogram(
        for type: TripType,
        metric: HistogramMetric = .count,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawHourData {
        return try Database.shared.inRead { db in
            var buckets = Array(repeating: 0.0, count: 24)

            let selectAgg: String
            switch metric {
            case .count: selectAgg = "COUNT(*)"
            case .distanceMeters: selectAgg = "COALESCE(SUM(distance_m), 0.0)"
            case .durationSecs: selectAgg = "COALESCE(SUM(duration_s), 0.0)"
            }

            let sql = """
                SELECT
                  CAST(strftime('%H', datetime(start_ts/1000, 'unixepoch', 'localtime')) AS INTEGER) AS hr,
                  \(selectAgg) AS v
                FROM trips
                WHERE type = ?
                \(buildDatePredicate(from: from, to: to))
                GROUP BY hr;
                """

            var s: OpaquePointer?
            defer { sqlite3_finalize(s) }
            guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
                throw DBError.sqlite(message: lastError(db))
            }

            var i: Int32 = 1
            sqlite3_bind_int(s, i, Int32(type.dbValue))
            i += 1
            bindDateParams(s, &i, from: from, to: to)

            while sqlite3_step(s) == SQLITE_ROW {
                guard sqlite3_column_type(s, 0) != SQLITE_NULL else { continue }
                let hr = Int(sqlite3_column_int(s, 0))
                let v = sqlite3_column_double(s, 1)
                if (0..<24).contains(hr) { buckets[hr] = v }
            }

            return RawHourData(values: buckets)
        }
    }

    static func fetchWeeklyInsights(
        for type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawWeekInsights {
        return try Database.shared.inRead { db in
            let datePred = buildDatePredicate(from: from, to: to)

            do {
                let sqlTotals = """
                    SELECT
                      COALESCE(SUM(distance_m), 0.0) AS total_meters,
                      COALESCE(SUM(duration_s), 0.0) AS total_secs,
                      COUNT(*) AS trip_count
                    FROM trips
                    WHERE type = ?\(datePred);
                    """
                var s: OpaquePointer?
                defer { sqlite3_finalize(s) }
                guard
                    sqlite3_prepare_v2(db, sqlTotals, -1, &s, nil) == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                var i: Int32 = 1
                sqlite3_bind_int(s, i, Int32(type.dbValue))
                i += 1
                bindDateParams(s, &i, from: from, to: to)

                var totalMeters = 0.0
                var totalSecs = 0.0
                var tripCount = 0
                if sqlite3_step(s) == SQLITE_ROW {
                    totalMeters = sqlite3_column_double(s, 0)
                    totalSecs = sqlite3_column_double(s, 1)
                    tripCount = Int(sqlite3_column_int64(s, 2))
                }

                let avgMeters =
                    tripCount > 0 ? (totalMeters / Double(tripCount)) : 0.0
                let avgSecs =
                    tripCount > 0 ? (totalSecs / Double(tripCount)) : 0.0

                let sqlMaxDist = """
                    SELECT COALESCE(MAX(distance_m), 0.0) FROM trips
                    WHERE type = ?\(datePred);
                    """
                var sMaxD: OpaquePointer?
                defer { sqlite3_finalize(sMaxD) }
                guard
                    sqlite3_prepare_v2(db, sqlMaxDist, -1, &sMaxD, nil)
                        == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                i = 1
                sqlite3_bind_int(sMaxD, i, Int32(type.dbValue))
                i += 1
                bindDateParams(sMaxD, &i, from: from, to: to)
                let longestMeters =
                    (sqlite3_step(sMaxD) == SQLITE_ROW)
                    ? sqlite3_column_double(sMaxD, 0) : 0.0

                let sqlMaxSecs = """
                    SELECT COALESCE(MAX(duration_s), 0.0) FROM trips
                    WHERE type = ?\(datePred);
                    """
                var sMaxS: OpaquePointer?
                defer { sqlite3_finalize(sMaxS) }
                guard
                    sqlite3_prepare_v2(db, sqlMaxSecs, -1, &sMaxS, nil)
                        == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                i = 1
                sqlite3_bind_int(sMaxS, i, Int32(type.dbValue))
                i += 1
                bindDateParams(sMaxS, &i, from: from, to: to)
                let longestSecs =
                    (sqlite3_step(sMaxS) == SQLITE_ROW)
                    ? sqlite3_column_double(sMaxS, 0) : 0.0

                let sqlBusiest = """
                    SELECT
                      CAST(strftime('%w', datetime(start_ts/1000, 'unixepoch', 'localtime')) AS INTEGER) AS dow,
                      COUNT(*) AS c
                    FROM trips
                    WHERE type = ?\(datePred)
                    GROUP BY dow
                    ORDER BY c DESC, dow ASC
                    LIMIT 1;
                    """
                var sBusy: OpaquePointer?
                defer { sqlite3_finalize(sBusy) }
                guard
                    sqlite3_prepare_v2(db, sqlBusiest, -1, &sBusy, nil)
                        == SQLITE_OK
                else {
                    throw DBError.sqlite(message: lastError(db))
                }
                i = 1
                sqlite3_bind_int(sBusy, i, Int32(type.dbValue))
                i += 1
                bindDateParams(sBusy, &i, from: from, to: to)
                var busiestDOW: Int32 = -1
                if sqlite3_step(sBusy) == SQLITE_ROW {
                    busiestDOW = sqlite3_column_int(sBusy, 0)
                }

                return RawWeekInsights(
                    totalMeters: totalMeters,
                    totalDurationSecs: totalSecs,
                    tripCount: tripCount,
                    avgTripMeters: avgMeters,
                    avgTripDurationSecs: avgSecs,
                    longestTripMeters: longestMeters,
                    longestTripDurationSecs: longestSecs,
                    busiestDowByCount: Int(busiestDOW)
                )
            }
        }
    }
    enum HistogramMetric { case count, distanceMeters, durationSecs }
    private static func buildDatePredicate(from: Int64?, to: Int64?) -> String {
        var p = ""
        if from != nil { p += " AND start_ts >= ?" }
        if to != nil { p += " AND start_ts <= ?" }
        return p
    }

    private static func bindDateParams(
        _ stmt: OpaquePointer?,
        _ index: inout Int32,
        from: Int64?,
        to: Int64?
    ) {
        if let from {
            sqlite3_bind_int64(stmt, index, from)
            index += 1
        }
        if let to {
            sqlite3_bind_int64(stmt, index, to)
            index += 1
        }
    }

    private static func sumDistanceMeters(
        for type: TripType,
        from: Int64?,
        to: Int64?,
        in db: OpaquePointer
    ) throws -> Double {
        let sql =
            "SELECT COALESCE(SUM(distance_m),0) FROM trips WHERE type=?"
            + buildDatePredicate(from: from, to: to) + ";"
        var s: OpaquePointer?
        defer { sqlite3_finalize(s) }
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        var i: Int32 = 1
        sqlite3_bind_int(s, i, Int32(type.dbValue))
        i += 1
        bindDateParams(s, &i, from: from, to: to)
        guard sqlite3_step(s) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return sqlite3_column_double(s, 0)
    }

    private static func sumDistanceMetersAllExcludingUnsortedTrash(
        from: Int64?,
        to: Int64?,
        in db: OpaquePointer
    ) throws -> Double {
        let sql =
            "SELECT COALESCE(SUM(distance_m),0) FROM trips WHERE type!=? AND type!=?"
            + buildDatePredicate(from: from, to: to) + ";"
        var s: OpaquePointer?
        defer { sqlite3_finalize(s) }
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        var i: Int32 = 1
        sqlite3_bind_int(s, i, Int32(TripType.unsorted.dbValue))
        i += 1
        sqlite3_bind_int(s, i, Int32(TripType.trash.dbValue))
        i += 1
        bindDateParams(s, &i, from: from, to: to)
        guard sqlite3_step(s) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return sqlite3_column_double(s, 0)
    }

    private static func countTrips(
        for type: TripType,
        from: Int64?,
        to: Int64?,
        in db: OpaquePointer
    ) throws -> Int {
        let sql =
            "SELECT COUNT(*) FROM trips WHERE type=?"
            + buildDatePredicate(from: from, to: to) + ";"
        var s: OpaquePointer?
        defer { sqlite3_finalize(s) }
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        var i: Int32 = 1
        sqlite3_bind_int(s, i, Int32(type.dbValue))
        i += 1
        bindDateParams(s, &i, from: from, to: to)
        guard sqlite3_step(s) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return Int(sqlite3_column_int64(s, 0))
    }

    private static func countTripsAllExcludingUnsortedTrash(
        from: Int64?,
        to: Int64?,
        in db: OpaquePointer
    ) throws -> Int {
        let sql =
            "SELECT COUNT(*) FROM trips WHERE type!=? AND type!=?"
            + buildDatePredicate(from: from, to: to) + ";"
        var s: OpaquePointer?
        defer { sqlite3_finalize(s) }
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        var i: Int32 = 1
        sqlite3_bind_int(s, i, Int32(TripType.unsorted.dbValue))
        i += 1
        sqlite3_bind_int(s, i, Int32(TripType.trash.dbValue))
        i += 1
        bindDateParams(s, &i, from: from, to: to)
        guard sqlite3_step(s) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return Int(sqlite3_column_int64(s, 0))
    }

    private static func sumDurationSeconds(
        for type: TripType,
        from: Int64?,
        to: Int64?,
        in db: OpaquePointer
    ) throws -> Double {
        let sql =
            "SELECT COALESCE(SUM(duration_s),0) FROM trips WHERE type=?"
            + buildDatePredicate(from: from, to: to) + ";"
        var s: OpaquePointer?
        defer { sqlite3_finalize(s) }
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        var i: Int32 = 1
        sqlite3_bind_int(s, i, Int32(type.dbValue))
        i += 1
        bindDateParams(s, &i, from: from, to: to)
        guard sqlite3_step(s) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return sqlite3_column_double(s, 0)
    }

    private static func sumDurationSecondsAllExcludingUnsortedTrash(
        from: Int64?,
        to: Int64?,
        in db: OpaquePointer
    ) throws -> Double {
        let sql =
            "SELECT COALESCE(SUM(duration_s),0) FROM trips WHERE type!=? AND type!=?"
            + buildDatePredicate(from: from, to: to) + ";"
        var s: OpaquePointer?
        defer { sqlite3_finalize(s) }
        guard sqlite3_prepare_v2(db, sql, -1, &s, nil) == SQLITE_OK else {
            throw DBError.sqlite(message: lastError(db))
        }
        var i: Int32 = 1
        sqlite3_bind_int(s, i, Int32(TripType.unsorted.dbValue))
        i += 1
        sqlite3_bind_int(s, i, Int32(TripType.trash.dbValue))
        i += 1
        bindDateParams(s, &i, from: from, to: to)
        guard sqlite3_step(s) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return sqlite3_column_double(s, 0)
    }

    static func count(for type: Int) throws -> Int {
        return try Database.shared.inRead { db in
            let sql = "SELECT COUNT(*) FROM trips WHERE type=?;"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK
            else {
                throw DBError.sqlite(message: lastError(db))
            }
            sqlite3_bind_int(stmt, 1, Int32(type))
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                throw DBError.sqlite(message: lastError(db))
            }
            return Int(sqlite3_column_int64(stmt, 0))
        }
    }

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
        return TripMeta(
            id: id,
            type: type,
            startTs: startTs,
            endTs: endTs,
            distanceM: distanceM,
            durationS: durationS,
            bboxMinLat: minLat,
            bboxMinLon: minLon,
            bboxMaxLat: maxLat,
            bboxMaxLon: maxLon,
            sizeBytes: sizeBytes,
            version: version
        )
    }

    private static func bindText(
        _ stmt: OpaquePointer?,
        _ idx: Int32,
        _ string: String
    ) {
        sqlite3_bind_text(stmt, idx, string, -1, SQLITE_TRANSIENT)
    }

    private static func lastError(_ db: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(db))
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(
    -1,
    to: sqlite3_destructor_type.self
)
