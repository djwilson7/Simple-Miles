import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("TimeUtility Tests")
struct TimeUtilityTests {
    
    @Test("Seconds formatter - positive values")
    func testSecondsFormatterPositive() {
        #expect(TimeUtility.formatDuration(0) == "0s")
        #expect(TimeUtility.formatDuration(30) == "30s")
        #expect(TimeUtility.formatDuration(60) == "1m")
        #expect(TimeUtility.formatDuration(90) == "1m 30s")
        #expect(TimeUtility.formatDuration(3600) == "1h")
        #expect(TimeUtility.formatDuration(3660) == "1h 1m")
        #expect(TimeUtility.formatDuration(7200) == "2h")
        #expect(TimeUtility.formatDuration(7320) == "2h 2m")
    }
    
    @Test("Seconds formatter - negative values")
    func testSecondsFormatterNegative() {
        #expect(TimeUtility.formatDuration(-30) == "-30s")
        #expect(TimeUtility.formatDuration(-60) == "-1m")
        #expect(TimeUtility.formatDuration(-3660) == "-1h 1m")
    }
    
    @Test("Day of week formatter")
    func testDOWFormatter() {
        #expect(TimeUtility.formatDayOfWeek(0) == "Sun")
        #expect(TimeUtility.formatDayOfWeek(1) == "Mon")
        #expect(TimeUtility.formatDayOfWeek(2) == "Tue")
        #expect(TimeUtility.formatDayOfWeek(3) == "Wed")
        #expect(TimeUtility.formatDayOfWeek(4) == "Thu")
        #expect(TimeUtility.formatDayOfWeek(5) == "Fri")
        #expect(TimeUtility.formatDayOfWeek(6) == "Sat")
        #expect(TimeUtility.formatDayOfWeek(7) == "?")
        #expect(TimeUtility.formatDayOfWeek(-1) == "?")
    }
    
    @Test("Date formatting")
    func testDateFormatting() {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2026, month: 5, day: 16)
        let date = calendar.date(from: components)!
        
        #expect(TimeUtility.formatDate(date) == "May 16, 2026")
    }
    
    @Test("Time formatting")
    func testTimeFormatting() {
        let calendar = Calendar(identifier: .gregorian)
        
        // Test PM with :00 removal
        var components = DateComponents(hour: 14, minute: 0) // 2:00 PM
        var date = calendar.date(from: components)!
        #expect(TimeUtility.formatTime(date) == "2pm")
        
        // Test AM with :00 removal
        components = DateComponents(hour: 9, minute: 0) // 9:00 AM
        date = calendar.date(from: components)!
        #expect(TimeUtility.formatTime(date) == "9am")
        
        // Test with minutes
        components = DateComponents(hour: 10, minute: 30) // 10:30 AM
        date = calendar.date(from: components)!
        #expect(TimeUtility.formatTime(date) == "10:30am")
        
        // Test 12 PM
        components = DateComponents(hour: 12, minute: 0)
        date = calendar.date(from: components)!
        #expect(TimeUtility.formatTime(date) == "12pm")
        
        // Test 12 AM (midnight)
        components = DateComponents(hour: 0, minute: 0)
        date = calendar.date(from: components)!
        #expect(TimeUtility.formatTime(date) == "12am")
    }
}
