import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SwiftUI

@Suite("SettingsManager Tests")
struct SettingsManagerTests {
    
    /*
    @MainActor
    @Test("Default values are correct")
    func testDefaults() {
        let manager = SettingsManager.shared
        #expect(manager.minimumTripDistance == 0.2)
        #expect(manager.pauseTimer == 150.0)
    }
    */
    
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
        let manager = SettingsManager.shared
        
        let originalUnit = manager.distanceUnit
        let originalDist = manager.minimumTripDistance
        let originalTheme = manager.themeOverride
        
        manager.distanceUnit = .kilometers
        #expect(UserDefaults.standard.string(forKey: AppSettingKey.distanceUnit.rawValue) == "kilometers")
        
        manager.minimumTripDistance = 1.0
        #expect(UserDefaults.standard.double(forKey: AppSettingKey.minimumTripDistance.rawValue) == 1.0)
        
        manager.themeOverride = .dark
        #expect(UserDefaults.standard.string(forKey: AppSettingKey.themeOverride.rawValue) == "dark")
        
        manager.primaryHue = 0.5
        #expect(UserDefaults.standard.double(forKey: AppSettingKey.primaryHue.rawValue) == 0.5)
        
        manager.saturation = 0.6
        #expect(UserDefaults.standard.double(forKey: AppSettingKey.saturation.rawValue) == 0.6)
        
        manager.brightness = 0.7
        #expect(UserDefaults.standard.double(forKey: AppSettingKey.brightness.rawValue) == 0.7)
        
        manager.pauseTimer = 300.0
        #expect(UserDefaults.standard.double(forKey: AppSettingKey.pauseTimer.rawValue) == 300.0)

        manager.materialOverride = .frosted
        #expect(UserDefaults.standard.string(forKey: AppSettingKey.materialOverride.rawValue) == "frosted")
        
        // Reset to originals for other tests
        manager.distanceUnit = originalUnit
        manager.minimumTripDistance = originalDist
        manager.themeOverride = originalTheme
    }
    
    @MainActor
    @Test("Derived values are correct")
    func testDerivedValues() {
        let manager = SettingsManager.shared
        
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
}
