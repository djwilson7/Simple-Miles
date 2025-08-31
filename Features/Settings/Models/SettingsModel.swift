import Foundation

enum SettingValue {
    case bool(Bool)
    case int(Int)          // also used for .menu (selected index)
    case double(Double)
    case string(String)
    case date(Date)        // stored as Double epoch seconds

    var any: Any {
        switch self {
        case .bool(let v):   return v
        case .int(let v):    return v
        case .double(let v): return v
        case .string(let v): return v
        case .date(let v):   return v
        }
    }
}

enum SettingType: Equatable {
    case bool
    case int
    case double
    case string
    case date    // persisted as Double seconds since 1970
    case menu    // persisted as Int (selected index)
}

struct SettingItem: Identifiable {
    var id: String { key }                 // stable
    let key: String                        // UserDefaults key
    let title: String
    let detail: String?
    let type: SettingType

    init(
        key: String,
        title: String,
        detail: String? = nil,
        type: SettingType,
    ) {
        self.key = key
        self.title = title
        self.detail = detail
        self.type = type
    }
}
