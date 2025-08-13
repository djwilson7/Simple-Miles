import Foundation

/// Represents the possible types of values a setting can hold.
enum SettingValue {
    case bool(Bool)
    case double(Double)
    case string(String)
    
    /// Enables direct function-like calls to extract the natural stored type.
    func callAsFunction() -> Any {
        switch self {
        case .bool(let b): return b
        case .double(let d): return d
        case .string(let s): return s
        }
    }
    
    /// Enables generic direct calls to extract as a type, or nil if not compatible.
    func callAsFunction<T>() -> T? {
        switch self {
        case .bool(let b): return b as? T
        case .double(let d): return d as? T
        case .string(let s): return s as? T
        }
    }
}

/// Represents the types of controls that can be used to manipulate a setting.
enum SettingControlType {
    case toggle
    case stepper(min: Double, max: Double, step: Double)
    case menu(options: [String])
}

/// Stores a single setting's value and persists it to UserDefaults.
final class SettingModel {
    let title: String
    let description: String
    let userDefaultsKey: String
    let controlType: SettingControlType
    private var _value: SettingValue
    var value: SettingValue {
        get { _value }
        set {
            _value = newValue
            switch newValue {
            case .bool(let boolValue):
                UserDefaults.standard.set(boolValue, forKey: userDefaultsKey)
            case .double(let doubleValue):
                UserDefaults.standard.set(doubleValue, forKey: userDefaultsKey)
            case .string(let stringValue):
                UserDefaults.standard.set(stringValue, forKey: userDefaultsKey)
            }
        }
    }
    
    /// Enables direct function-like calls on value for ergonomic access.
    func callAsFunction() -> Any {
        value()
    }
    
    /// Enables generic direct calls to extract as a type, or nil if not compatible.
    func callAsFunction<T>() -> T? {
        value()
    }

    init(title: String, description: String, userDefaultsKey: String, controlType: SettingControlType, value: SettingValue) {
        self.title = title
        self.description = description
        self.userDefaultsKey = userDefaultsKey
        self.controlType = controlType
        
        if let stored = UserDefaults.standard.object(forKey: userDefaultsKey) {
            switch value {
            case .bool:
                if let boolValue = stored as? Bool {
                    self._value = .bool(boolValue)
                } else {
                    self._value = value
                }
            case .double:
                if let doubleValue = stored as? Double {
                    self._value = .double(doubleValue)
                } else if let doubleValue = stored as? NSNumber {
                    self._value = .double(doubleValue.doubleValue)
                } else {
                    self._value = value
                }
            case .string:
                if let stringValue = stored as? String {
                    self._value = .string(stringValue)
                } else {
                    self._value = value
                }
            }
        } else {
            self._value = value
        }
    }
}
