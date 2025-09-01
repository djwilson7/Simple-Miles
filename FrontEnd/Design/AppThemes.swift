import SwiftUI
import MapKit

enum AppTheme {
    enum Colors {
        static var primaryText: Color { Color("PrimaryText") }
        static var primaryText80: Color { primaryText.opacity(0.8) }
        static var primaryText60: Color { primaryText.opacity(0.6) }
        static var primaryText50: Color { primaryText.opacity(0.5) }
        
        static var primaryPath: Color { Color("PrimaryPath") }
        static var primaryPath80: Color { primaryPath.opacity(0.8) }
        static var primaryPath60: Color { primaryPath.opacity(0.6) }
        
        static var pathHalo: Color { Color("PathHalo").opacity(0.7) }
        static var pathHalo30: Color { pathHalo.opacity(0.3) }
        
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

