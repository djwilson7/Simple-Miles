
//  Migrations.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import SQLite3

/// Schema migrations for the SimpleMiles database.
/// Uses PRAGMA user_version to track the schema version.
enum Migrations {
    /// Latest schema version for the app bundle.
    private static let latest: Int32 = 1

    /// Entry point. Idempotent and safe to call on every app launch.
    static func migrate(on database: Database) throws {
        try database.inWrite { db in
            let current = try userVersion(db)
            if current == latest { return }

            switch current {
            case 0:
                // Fresh DB. Create v1 schema.
                try createV1(db)
                try setUserVersion(db, to: 1)
                fallthrough
            case 1:
                // Up-to-date for now. Future versions will be added here.
                break
            default:
                // If we somehow see a newer version, do nothing (forward-compat stubb).
                break
            }
        }
    }

    // MARK: - v1

    /// v1: initial schema with trips (metadata) and trip_blobs (db-backed blobs).
    private static func createV1(_ db: OpaquePointer) throws {
        let tripsSQL = """
        CREATE TABLE IF NOT EXISTS trips (
          id            TEXT PRIMARY KEY,
          type          INTEGER NOT NULL,
          start_ts      INTEGER NOT NULL,
          end_ts        INTEGER NOT NULL,
          distance_m    REAL    NOT NULL,
          duration_s    REAL    NOT NULL,
          bbox_min_lat  INTEGER NOT NULL,
          bbox_min_lon  INTEGER NOT NULL,
          bbox_max_lat  INTEGER NOT NULL,
          bbox_max_lon  INTEGER NOT NULL,
          size_bytes    INTEGER NOT NULL DEFAULT 0,
          version       INTEGER NOT NULL DEFAULT 1
        );
        CREATE INDEX IF NOT EXISTS trips_type_ts ON trips(type, start_ts DESC);
        CREATE INDEX IF NOT EXISTS trips_ts      ON trips(start_ts DESC);
        """
        try exec(db, sql: tripsSQL)

        let blobsSQL = """
        CREATE TABLE IF NOT EXISTS trip_blobs (
          trip_id          TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
          kind             TEXT    NOT NULL CHECK (kind IN ('raw','display')),
          codec            TEXT    NOT NULL,
          encoding_version INTEGER NOT NULL,
          bytes            BLOB    NOT NULL,
          PRIMARY KEY (trip_id, kind)
        );
        """
        try exec(db, sql: blobsSQL)
    }

    // MARK: - Helpers

    private static func userVersion(_ db: OpaquePointer) throws -> Int32 {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else {
            throw DBError.sqlite(message: lastError(db))
        }
        return sqlite3_column_int(stmt, 0)
    }

    private static func setUserVersion(_ db: OpaquePointer, to value: Int32) throws {
        let sql = "PRAGMA user_version=\(value);"
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw DBError.sqlite(message: lastError(db))
        }
    }

    private static func exec(_ db: OpaquePointer, sql: String) throws {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw DBError.sqlite(message: lastError(db))
        }
    }

    private static func lastError(_ db: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(db))
    }
}

