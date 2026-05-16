import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SwiftUI

@Suite("SettingsManager Tests", .serialized)
struct SettingsManagerTests {
    
    @MainActor
    private func makeCleanManager() -> (SettingsManager, UserDefaults) {
        let suiteName = "SettingsManagerTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (SettingsManager(userDefaults: defaults), defaults)
    }
    
    @MainActor
    @Test("Default values are correct")
    func testDefaults() {
        let (manager, _) = makeCleanManager()
        #expect(manager.minimumTripDistance == 0.2)
        #expect(manager.pauseTimer == 150.0)
        #expect(manager.distanceUnit == .miles)
        #expect(manager.themeOverride == .system)
    }
    
    @MainActor
    @Test("DistanceUnit details")
    func testDistanceUnit() {
        #expect(DistanceUnit.miles.displayName == "Miles")
        #expect(DistanceUnit.miles.abb == "mi")
        #expect(DistanceUnit.miles.factor == 1609.34)
        #expect(DistanceUnit.kilometers.displayName == "Kilometers")
        #expect(DistanceUnit.kilometers.abb == "km")
        #expect(DistanceUnit.kilometers.factor == 1000.0)
    }

    @MainActor
    @Test("ThemeOverride details")
    func testThemeOverride() {
        #expect(ThemeOverride.system.displayName == "System")
        #expect(ThemeOverride.system.colorScheme == nil)
        #expect(ThemeOverride.light.colorScheme == .light)
        #expect(ThemeOverride.dark.colorScheme == .dark)
    }

    @MainActor
    @Test("MaterialOverride display names")
    func testMaterialOverride() {
        #expect(MaterialOverride.clear.displayName == "Clear")
        #expect(MaterialOverride.frosted.displayName == "Frosted")
        #expect(MaterialOverride.none.displayName == "Solid")
    }

    @MainActor
    @Test("Updating settings persists them")
    func testPersistence() {
        let (manager, defaults) = makeCleanManager()
        
        manager.distanceUnit = .kilometers
        #expect(defaults.string(forKey: AppSettingKey.distanceUnit.rawValue) == "kilometers")
        
        manager.minimumTripDistance = 1.0
        #expect(defaults.double(forKey: AppSettingKey.minimumTripDistance.rawValue) == 1.0)
        
        manager.themeOverride = .dark
        #expect(defaults.string(forKey: AppSettingKey.themeOverride.rawValue) == "dark")
        
        manager.primaryHue = 0.5
        #expect(defaults.double(forKey: AppSettingKey.primaryHue.rawValue) == 0.5)
        
        manager.saturation = 0.6
        #expect(defaults.double(forKey: AppSettingKey.saturation.rawValue) == 0.6)
        
        manager.brightness = 0.7
        #expect(defaults.double(forKey: AppSettingKey.brightness.rawValue) == 0.7)
        
        manager.pauseTimer = 300.0
        #expect(defaults.double(forKey: AppSettingKey.pauseTimer.rawValue) == 300.0)

        manager.materialOverride = .frosted
        #expect(defaults.string(forKey: AppSettingKey.materialOverride.rawValue) == "frosted")
    }
    
    @MainActor
    @Test("Derived values are correct")
    func testDerivedValues() {
        let (manager, _) = makeCleanManager()
        
        manager.distanceUnit = .miles
        manager.minimumTripDistance = 1.0
        #expect(manager.minDistanceMeters == 1609.34)
        
        manager.distanceUnit = .kilometers
        #expect(manager.minDistanceMeters == 1000.0)
        
        manager.primaryHue = 0.5
        manager.saturation = 0.8
        manager.brightness = 0.9
        // We can't easily check internal color components, but we verify it doesn't crash
        _ = manager.accentColor
        #expect(Bool(true))
    }

    @MainActor
    @Test("Erase all data")
    func testEraseAllData() throws {
        let (manager, _) = makeCleanManager()
        
        // Insert a dummy trip using TripsDAO
        let meta = TripMeta(id: "test-id", type: 1, startTs: 1000, endTs: 2000, distanceM: 100, durationS: 10, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 100, version: 1)
        try TripsDAO.insertOrReplace(meta)
        
        manager.eraseAllData()
        
        // Verify trip is gone
        let trips = try TripsDAO.fetchAllTrips()
        #expect(trips.isEmpty)
    }

    @MainActor
    @Test("Export CSV - empty")
    func testExportCSVEmpty() throws {
        let (manager, _) = makeCleanManager()
        manager.eraseAllData() // ensure clean
        
        let url = manager.exportCSV()
        #expect(url == nil)
    }

    @MainActor
    @Test("Export CSV - with data")
    func testExportCSVWithData() throws {
        let (manager, _) = makeCleanManager()
        manager.eraseAllData()
        
        // Insert dummy trips of different categories
        // Type 1 = Business, Type 0 = Personal
        let meta1 = TripMeta(id: "trip-1", type: 1, startTs: 1000, endTs: 2000, distanceM: 1609.34, durationS: 10, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 100, version: 1)
        let meta2 = TripMeta(id: "trip-2", type: 0, startTs: 3000, endTs: 4000, distanceM: 1609.34, durationS: 10, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 100, version: 1)
        
        try TripsDAO.insertOrReplace(meta1)
        try TripsDAO.insertOrReplace(meta2)
        
        let url = manager.exportCSV()
        #expect(url != nil)
        
        if let url = url {
            let content = try String(contentsOf: url)
            #expect(content.contains("Trip ID,Category,Date,Start Time,End Time,Distance (Miles),Duration,Raw Meters,Raw Seconds"))
            #expect(content.contains("trip-1"))
            #expect(content.contains("Business"))
            #expect(content.contains("trip-2"))
            #expect(content.contains("Personal"))
            
            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }

    @MainActor
    @Test("All DistanceUnit options")
    func testDistanceUnitOptions() {
        for unit in DistanceUnit.allCases {
            #expect(unit.id == unit.rawValue)
            _ = unit.displayName
            _ = unit.abb
            _ = unit.factor
        }
    }

    @MainActor
    @Test("All ThemeOverride options")
    func testThemeOverrideOptions() {
        for theme in ThemeOverride.allCases {
            #expect(theme.id == theme.rawValue)
            _ = theme.displayName
            _ = theme.colorScheme
        }
    }

    @MainActor
    @Test("All MaterialOverride options")
    func testMaterialOverrideOptions() {
        for mat in MaterialOverride.allCases {
            #expect(mat.id == mat.rawValue)
            _ = mat.displayName
        }
    }
}
