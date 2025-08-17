//
//  TimeUtility.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/13/25.
//
import Foundation

struct TimeUtility {
    static func formatter(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        
        if hours > 0 {
            // Over an hour
            if minutes > 0 && seconds > 0 {
                return "\(hours)h \(minutes)min \(seconds)s"
            } else if minutes > 0 {
                return "\(hours)h \(minutes)min"
            } else {
                return "\(hours)h"
            }
        } else if minutes > 0 {
            // Over a minute but under an hour
            if seconds > 0 {
                return "\(minutes)min \(seconds)s"
            } else {
                return "\(minutes)min"
            }
        } else {
            // Under a minute
            return "\(seconds)s"
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
