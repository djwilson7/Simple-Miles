import Foundation

enum PrivacyConsentLevel: String, CaseIterable, CustomStringConvertible {
    case none           // user opted out entirely
    case diagnostics    // anonymous crash or usage data
    case fullSharing    // allows aggregate or session metadata sharing
    
    var description: String {
        switch self{
        case .none: "No Sharing."
        case .diagnostics: "Anonymous crash or usage data."
        case .fullSharing: "Aggregate or session metadata sharing."
        }
    }
}
