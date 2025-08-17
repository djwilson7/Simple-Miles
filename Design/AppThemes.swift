//
//  AppTheme.swift
//  SimpleMiles
//
//  Central theme: colors + typography + a map-based preview.
//  Define the corresponding Color Assets named exactly as documented below.
//
import SwiftUI
import MapKit

// MARK: - Theme Root
enum AppTheme {
    // MARK: - Colors
    enum Colors {
        //Primary Text (light -> black) (dark -> white)
        static var primaryText: Color { Color("PrimaryText") }
        static var primaryText80: Color { primaryText.opacity(0.8) }
        static var primaryText60: Color { primaryText.opacity(0.6) }
        static var primaryText50: Color { primaryText.opacity(0.5) }
        
        static var primaryPath: Color { Color("PrimaryPath") }
        static var primaryPath80: Color { primaryPath.opacity(0.8) }
        static var primaryPath60: Color { primaryPath.opacity(0.6) }
        
        static var pathHalo: Color { Color("PathHalo").opacity(0.7) }
        static var pathHalo30: Color { pathHalo.opacity(0.3) }
        
        // Convenience aliases (optional)
        static var primaryDark: Color   { Color("CP-Dark") }
        static var primaryMedium: Color { Color("CP-Medium") }
        static var primaryLight: Color  { Color("CP-Light") }
        
        static var secondaryDark: Color   { Color("CS-Dark") }
        static var secondaryMedium: Color { Color("CS-Medium") }
        static var secondaryLight: Color  { Color("CS-Light") }

        static var accentDark: Color   { Color("CA-Dark") }
        static var accentMedium: Color { Color("CA-Medium") }
        static var accentLight: Color  { Color("CA-Light") }
        
    }

}

