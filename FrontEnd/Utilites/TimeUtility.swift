import Foundation

struct TimeUtility {
    static func formatter(_ seconds: TimeInterval) -> String {
        let prefix = seconds < 0 ? "-" : ""

        let totalSeconds = Int(abs(seconds))
        let s = totalSeconds % 60
        let m = (totalSeconds / 60) % 60
        let h = totalSeconds / 3600
        
        if h > 0 && m != 0 {
            return "\(prefix)\(h)h \(m)min"
        } else if h > 0 {
            return "\(prefix)\(h)h"
        } else if m > 0 && s != 0 {
            return "\(prefix)\(m)min \(s)s"
        } else if m > 0 {
            return "\(prefix)\(m)min"
        } else { 
            return "\(prefix)\(s)s"
        }
    }
    
    static func formatter(_ dow: Int) -> String {
        switch dow {
        case 0: return "Sun"
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        default: return "?"
        }
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date).replacingOccurrences(of: ":00pm", with: "pm").replacingOccurrences(of: ":00am", with: "am")
    }
}
