//
//  TimeUtility.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/13/25.
//
import Foundation

struct TimeUtility {
    static func formatter(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        
        if hours > 0 {
            // Over an hour
            return "\(hours)h \(minutes)min"
        } else if minutes > 0 {
            // Over a minute but under an hour
            return "\(minutes)min"
        } else {
            // Under a minute
            return "\(seconds)s"
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
