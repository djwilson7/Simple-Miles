import Foundation
import SQLite3

enum Migrations {
    static var latest: Int32 = 1

    static func migrate(on database: Database) throws {
        try database.inWrite { db in
            let current = try userVersion(db)
            if current == latest { return }

            switch current {
            case 0:
                try createV1(db)
                try setUserVersion(db, version: 1)
                fallthrough
            case 1:
                break
            default:
                break
            }
        }
    }

    static func createV1(_ db: OpaquePointer) throws {
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

        let trashSQL = """
        CREATE TABLE IF NOT EXISTS trash (
          trip_id     TEXT PRIMARY KEY REFERENCES trips(id) ON DELETE CASCADE,
          deleted_at  INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS trash_deleted_at ON trash(deleted_at);
        """
        try exec(db, sql: trashSQL)

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
static func userVersion(_ db: OpaquePointer) throws -> Int32 {
    var stmt: OpaquePointer?
    defer { sqlite3_finalize(stmt) }
    guard sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &stmt, nil) == SQLITE_OK else {
        throw DBError.sqlite(message: lastError(db))
    }
    guard sqlite3_step(stmt) == SQLITE_ROW else {
        throw DBError.sqlite(message: lastError(db))
    }
    return sqlite3_column_int(stmt, 0)
}

static func setUserVersion(_ db: OpaquePointer, version: Int32) throws {
    let sql = "PRAGMA user_version = \(version);"
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

