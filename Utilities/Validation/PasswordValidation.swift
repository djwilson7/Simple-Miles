//
//  PasswordValidator.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation

struct PasswordValidator {
    enum PasswordValidationError: String, Error, CustomStringConvertible {
        case tooShort = "Password must be at least 8 characters long."
        case onlyWhitespace = "Password cannot be empty or whitespace."
        case missingUppercase = "Password must contain at least one uppercase letter."
        case missingLowercase = "Password must contain at least one lowercase letter."
        case missingDigit = "Password must contain at least one digit."
        case missingSpecialCharacter = "Password must contain at least one special character."

        var description: String { rawValue }
    }

    static func validate(_ password: String) -> Result<Void, PasswordValidationError> {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.onlyWhitespace)
        }

        guard trimmed.count >= 8 else {
            return .failure(.tooShort)
        }

        let uppercaseRegex = ".*[A-Z]+.*"
        let lowercaseRegex = ".*[a-z]+.*"
        let digitRegex = ".*[0-9]+.*"
        let specialCharRegex = ".*[!@#$%^&*(),.?\":{}|<>]+.*"

        if !NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: trimmed) {
            return .failure(.missingUppercase)
        }

        if !NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: trimmed) {
            return .failure(.missingLowercase)
        }

        if !NSPredicate(format: "SELF MATCHES %@", digitRegex).evaluate(with: trimmed) {
            return .failure(.missingDigit)
        }

        if !NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: trimmed) {
            return .failure(.missingSpecialCharacter)
        }

        return .success(())
    }
}
