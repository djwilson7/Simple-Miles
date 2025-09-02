import SwiftUI
import MapKit

enum AppTheme {
    enum Colors {
        static var primaryText: Color { Color("PrimaryText") }
        static var primaryText80: Color { primaryText.opacity(0.8) }
        static var primaryText60: Color { primaryText.opacity(0.6) }
        static var primaryText50: Color { primaryText.opacity(0.5) }
       
        static var primaryPath: Color { Color("PrimaryPath") }
        static var primaryPath60: Color { primaryPath.opacity(0.6) }
      
        static var pathHalo: Color { Color("PathHalo").opacity(0.7) }
    }

}

