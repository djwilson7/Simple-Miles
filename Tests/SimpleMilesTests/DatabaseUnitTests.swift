import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SQLite3

@Suite("Database Unit Tests", .serialized)
struct DatabaseUnitTests {
    
    @Test("Rollback logic")
    func testRollback() throws {
        let db = Database.shared
        try? db.exec("CREATE TABLE test_rollback (id TEXT);")
        
        do {
            try db.inWrite { handle in
                sqlite3_exec(handle, "INSERT INTO test_rollback (id) VALUES ('fail');", nil, nil, nil)
                throw DBError.sqlite(message: "Simulated failure")
            }
        } catch {
            // Should be rolled back
        }
        
        db.inRead { handle in
            var stmt: OpaquePointer?
            sqlite3_prepare_v2(handle, "SELECT count(*) FROM test_rollback;", -1, &stmt, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                let count = sqlite3_column_int(stmt, 0)
                #expect(count == 0)
            }
            sqlite3_finalize(stmt)
        }
        
        try? db.exec("DROP TABLE test_rollback;")
    }
    
    @Test("Transaction methods")
    func testTransactions() throws {
        let db = Database.shared
        try db.inRead { handle in
            try db.begin(handle)
            try db.commit(handle)
            
            try db.begin(handle)
            try db.rollback(handle)
        }
    }
    
    @Test("File protection")
    func testProtection() throws {
        let db = Database.shared
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("protect-test")
        try? "test".write(to: url, atomically: true, encoding: .utf8)
        try db.applyFileProtection(at: url)
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Database execute invalid SQL")
    func testExecInvalid() {
        let db = Database.shared
        #expect(throws: DBError.self) {
            try db.exec("INVALID SQL;")
        }
    }

    @Test("Ensure directory exists")
    func testEnsureDirectory() throws {
        let url = try Database.databaseURL()
        // Calling it twice to hit the branch where directory already exists
        try Database.ensureDirectory(url.deletingLastPathComponent())
        try Database.ensureDirectory(url.deletingLastPathComponent())
        // Verified by no throw
    }

    @Test("Pragma invalid")
    func testPragmaInvalid() throws {
        let db = Database.shared
        _ = try db.inWrite { handle in
            #expect(throws: DBError.self) {
                try db.pragma(handle, name: "invalid syntax", value: "value")
            }
        }
    }
}
