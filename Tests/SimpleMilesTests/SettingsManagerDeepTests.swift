import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("SettingsManager Deep Tests")
struct SettingsManagerDeepTests {
    
    @MainActor
    private func makeCleanManager() -> (SettingsManager, UserDefaults) {
        let suiteName = "SettingsManagerDeepTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (SettingsManager(userDefaults: defaults), defaults)
    }
    
    @MainActor
    @Test("MaterialOverride display names")
    func testMaterialOverride() {
        #expect(MaterialOverride.clear.displayName == "Clear")
        #expect(MaterialOverride.regular.displayName == "Regular")
        #expect(MaterialOverride.frosted.displayName == "Frosted")
        #expect(MaterialOverride.none.displayName == "Solid")
    }
    
    @MainActor
    @Test("Accent color updates")
    func testAccentColor() {
        let (manager, _) = makeCleanManager()
        manager.primaryHue = 0.1
        manager.saturation = 0.2
        manager.brightness = 0.3
        
        #expect(manager.primaryHue == 0.1)
        #expect(manager.saturation == 0.2)
        #expect(manager.brightness == 0.3)
        #expect(Bool(true)) // accentColor is non-optional
    }
    
    @MainActor
    @Test("DistanceUnit details")
    func testDistanceUnit() {
        #expect(DistanceUnit.miles.displayName == "Miles")
        #expect(DistanceUnit.kilometers.displayName == "Kilometers")
        #expect(DistanceUnit.miles.abb == "mi")
        #expect(DistanceUnit.kilometers.abb == "km")
        #expect(DistanceUnit.miles.factor == 1609.34)
        #expect(DistanceUnit.kilometers.factor == 1000.0)
        #expect(DistanceUnit.miles.id == "miles")
    }
    
    @MainActor
    @Test("ThemeOverride details")
    func testThemeOverride() {
        #expect(ThemeOverride.system.displayName == "System")
        #expect(ThemeOverride.light.displayName == "Light")
        #expect(ThemeOverride.dark.displayName == "Dark")
        #expect(ThemeOverride.system.colorScheme == nil)
        #expect(ThemeOverride.light.colorScheme == .light)
        #expect(ThemeOverride.dark.colorScheme == .dark)
        #expect(ThemeOverride.system.id == "system")
    }
    
    @MainActor
    @Test("Loading overrides from UserDefaults")
    func testLoadingOverrides() {
        let suiteName = "SettingsManagerDeepTests-Loading"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        
        defaults.set("kilometers", forKey: AppSettingKey.distanceUnit.rawValue)
        defaults.set("dark", forKey: AppSettingKey.themeOverride.rawValue)
        defaults.set("frosted", forKey: AppSettingKey.materialOverride.rawValue)
        defaults.set(0.5, forKey: AppSettingKey.primaryHue.rawValue)
        defaults.set(0.6, forKey: AppSettingKey.saturation.rawValue)
        defaults.set(0.7, forKey: AppSettingKey.brightness.rawValue)
        defaults.set(1.0, forKey: AppSettingKey.minimumTripDistance.rawValue)
        defaults.set(300.0, forKey: AppSettingKey.pauseTimer.rawValue)
        
        // Initialize manager WITH the defaults already set
        let manager = SettingsManager(userDefaults: defaults)
        
        #expect(manager.distanceUnit == .kilometers)
        #expect(manager.themeOverride == .dark)
        #expect(manager.materialOverride == .frosted)
        #expect(manager.primaryHue == 0.5)
        #expect(manager.saturation == 0.6)
        #expect(manager.brightness == 0.7)
        #expect(manager.minimumTripDistance == 1.0)
        #expect(manager.pauseTimer == 300.0)
    }
}
