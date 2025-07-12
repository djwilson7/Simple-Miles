//
//  EmailValidation.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//
import Foundation

struct EmailValidator {
    static func isValid(_ email: String) -> Bool {
        // Reject newline and carriage return characters
        if email.contains(where: { $0.isNewline || $0 == "\r" }) {
            return false
        }
        
        // Local part (username) must:
        // - Not start/end with a dot
        // - Not contain consecutive dots
        // - Contain only alphanumerics and . _ + -
        let userPart = #"^(?!\.)(?!.*\.\.)[A-Za-z0-9._+-]{1,64}(?<!\.)"#
        
        // Domain must:
        // - Start with @
        // - Contain valid domain segments separated by dots (no underscores)
        let domainPart = #"@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*"#
        
        // Suffix must:
        // - Start with a dot
        // - Be 2 to 6 letters long (e.g., .com, .net)
        let suffixPart = #"\.[A-Za-z]{2,6}$"#
        let fullPattern = userPart + domainPart + suffixPart
        return email.range(of: fullPattern, options: .regularExpression) != nil
    }
}
