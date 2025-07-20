import Foundation

enum PrivacyConsentLevel: String, CaseIterable {
    case none           // user opted out entirely
    case diagnostics    // anonymous crash or usage data
    case fullSharing    // allows aggregate or session metadata sharing
}
