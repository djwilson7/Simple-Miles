// Features/Settings/Models/ColorPreferenceEnums.swift
import Foundation

enum SystemColorTheme: String, CaseIterable, CustomStringConvertible {
    case system     // Follows device setting
    case light
    case dark

    var label: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        }
    }
    
    var description: String {
        switch self {
        case .system: "Follow System"
        case .light: "Light Mode"
        case .dark: "Dark Mode"
        }
    }
}

enum AccessibilityColorTheme: String, CaseIterable, CustomStringConvertible {
    case normal
    case colorBlind
    case highContrast
    case dyslexiaFriendly

    var label: String {
        switch self {
        case .normal: return "Default"
        case .colorBlind: return "Color Blind"
        case .highContrast: return "High Contrast"
        case .dyslexiaFriendly: return "Dyslexia Friendly"
        }
    }
    
    var description: String {
        switch self {
        case .normal: "Normal Vision"
        case .colorBlind: "Color Blind Safe"
        case .highContrast: "High Contrast"
        case .dyslexiaFriendly: "Dyslexia Friendly"
        }
    }
}

enum AppColorTheme: String, CaseIterable, CustomStringConvertible {
    case classic
    case festive
    case stPatricks
    case halloween
    case winter

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .festive: return "Festive"
        case .stPatricks: return "St. Patrick's Day"
        case .halloween: return "Halloween"
        case .winter: return "Winter Wonderland"
        }
    }
    
    var description: String {
        switch self {
        case .classic: "Classic"
        case .festive: "Festive"
        case .stPatricks : "St. Patrick's Day"
        case .halloween: "Halloween"
        case .winter: "Winter Wonderland"
        }
    }
}
