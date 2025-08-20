//
//  Database.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//


//
//  Database.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import SQLite3

/// Lightweight SQLite wrapper for SimpleMiles.
/// - Responsibilities:
///   - Create/open the DB under Library/Application Support/SimpleMiles/Database/Trips.sqlite
///   - Enable WAL, foreign keys, busy timeout
///   - Apply iOS file protection to .sqlite, -wal, -shm
///   - Run schema migrations via `Migrations.migrate(on:)`
///   - Provide tiny helpers for read/write/transactions
final class Database {
    static let shared = Database()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.simplemiles.db", qos: .userInitiated)

    private init() {
        do {
            let url = try Database.databaseURL()
            try Database.ensureDirectory(url.deletingLastPathComponent())
            try open(at: url)
            try configure()
            try applyFileProtection(at: url)
            try Migrations.migrate(on: self)
        } catch {
            assertionFailure("Database init failed: \(error)")
        }
    }

    deinit { close() }

    // MARK: - Public entry points

    /// Execute a block on the DB queue (read-only safe calls)
    func inRead<T>(_ block: (OpaquePointer) throws -> T) rethrows -> T {
        return try queue.sync { [unowned self] in
            guard let db = self.db else { throw DBError.closed }
            return try block(db)
        }
    }

    /// Execute a block on the DB queue (write allowed). Wraps in a transaction by default.
    func inWrite<T>(_ block: (OpaquePointer) throws -> T) throws -> T {
        return try queue.sync { [unowned self] in
            guard let db = self.db else { throw DBError.closed }
            try begin(db)
            do {
                let result = try block(db)
                try commit(db)
                return result
            } catch {
                try? rollback(db)
                throw error
            }
        }
    }

    // MARK: - Basic exec helpers
    
    func exec(_ sql: String) throws -> Void {
        try inWrite { db in
            if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
                throw DBError.sqlite(message: lastError(db))
            }
        }
    }

    // MARK: - Internals

    private func open(at url: URL) throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let rc = sqlite3_open_v2(url.path, &handle, flags, nil)
        guard rc == SQLITE_OK, let db = handle else {
            throw DBError.openFailed(message: String(cString: sqlite3_errstr(rc)))
        }
        self.db = db
    }

    private func close() {
        guard let db else { return }
        _ = sqlite3_close(db)
        self.db = nil
    }

    private func configure() throws {
        try inRead { db in
            // WAL for concurrent reads/writes and crash safety
            try self.pragma(db, name: "journal_mode", value: "WAL")
            // Reasonable defaults
            try self.pragma(db, name: "synchronous", value: "NORMAL")
            try self.pragma(db, name: "foreign_keys", value: "ON")
            // Busy timeout to avoid SQLITE_BUSY under light contention
            if sqlite3_busy_timeout(db, 5000) != SQLITE_OK {
                throw DBError.sqlite(message: lastError(db))
            }
        }
    }

    private func pragma(_ db: OpaquePointer, name: String, value: String) throws {
        let sql = "PRAGMA \(name)=\(value);"
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            throw DBError.sqlite(message: lastError(db))
        }
    }

    private func begin(_ db: OpaquePointer) throws {
        if sqlite3_exec(db, "BEGIN IMMEDIATE;", nil, nil, nil) != SQLITE_OK {
            throw DBError.sqlite(message: lastError(db))
        }
    }

    private func commit(_ db: OpaquePointer) throws {
        if sqlite3_exec(db, "COMMIT;", nil, nil, nil) != SQLITE_OK {
            throw DBError.sqlite(message: lastError(db))
        }
    }

    private func rollback(_ db: OpaquePointer) throws {
        _ = sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
    }

    // MARK: - File system helpers

    static func databaseURL() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory,
                              in: .userDomainMask,
                              appropriateFor: nil,
                              create: true)
        let dir = base.appendingPathComponent("SimpleMiles/Database", isDirectory: true)
        return dir.appendingPathComponent("Trips.sqlite")
    }

    static func ensureDirectory(_ url: URL) throws {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: url.path, isDirectory: &isDir) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func applyFileProtection(at dbURL: URL) throws {
        #if os(iOS)
        let fm = FileManager.default
        let attrs: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        try fm.setAttributes(attrs, ofItemAtPath: dbURL.path)
        // Also set protection on WAL/SHM if they exist now; if not, they'll inherit from directory
        let wal = dbURL.appendingPathExtension("-wal")
        let shm = dbURL.appendingPathExtension("-shm")
        if fm.fileExists(atPath: wal.path) { try? fm.setAttributes(attrs, ofItemAtPath: wal.path) }
        if fm.fileExists(atPath: shm.path) { try? fm.setAttributes(attrs, ofItemAtPath: shm.path) }
        #endif
    }

    private func lastError(_ db: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(db))
    }
}

// MARK: - Errors

enum DBError: Error, LocalizedError {
    case openFailed(message: String)
    case sqlite(message: String)
    case closed

    var errorDescription: String? {
        switch self {
        case .openFailed(let message): return "DB open failed: \(message)"
        case .sqlite(let message): return "SQLite error: \(message)"
        case .closed: return "Database is closed"
        }
    }
}
