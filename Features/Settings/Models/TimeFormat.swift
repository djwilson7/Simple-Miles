import Foundation

enum TimeFormat: String, CaseIterable {
    case twelveHour
    case twentyFourHour

    var label: String {
        switch self {
        case .twelveHour: "12-Hour"
        case .twentyFourHour: "24-Hour"
        }
    }

    var systemFormat: String {
        switch self {
        case .twelveHour: "h:mm a"
        case .twentyFourHour: "HH:mm"
        }
    }

    func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = systemFormat
        return formatter.string(from: date)
    }
}
