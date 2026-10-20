import Foundation

public enum PasswordStrength: Int, Sendable {
    case veryWeak = 0
    case weak = 1
    case fair = 2
    case strong = 3
    case veryStrong = 4

    public var title: String {
        switch self {
        case .veryWeak: return "Very Weak"
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }

    public var isSufficient: Bool {
        return self.rawValue >= PasswordStrength.fair.rawValue
    }
}

public struct InputValidator: Sendable {
    public static let shared = InputValidator()

    // MARK: - Email Validation (RFC 5322 Simplified)
    public static func validateEmail(_ email: String) -> (isValid: Bool, error: String?) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (false, "Email address is required.")
        }
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard predicate.evaluate(with: trimmed) else {
            return (false, "Enter a valid email address (e.g. name@domain.com).")
        }
        return (true, nil)
    }

    // MARK: - Hostname Validation (RFC 1123 & RFC 952)
    public static func validateHostname(_ hostname: String) -> (isValid: Bool, error: String?) {
        let trimmed = hostname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            return (false, "Hostname is required.")
        }
        guard trimmed.count <= 253 else {
            return (false, "Hostname cannot exceed 253 characters.")
        }

        let labels = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard !labels.isEmpty else {
            return (false, "Invalid hostname format.")
        }

        let labelRegex = #"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", labelRegex)

        for label in labels {
            if label.isEmpty {
                return (false, "Hostname cannot contain empty labels or consecutive dots.")
            }
            if label.count > 63 {
                return (false, "Hostname labels cannot exceed 63 characters.")
            }
            if !predicate.evaluate(with: String(label)) {
                return (false, "Hostname labels must contain only alphanumeric characters and hyphens, and cannot start or end with a hyphen.")
            }
        }

        return (true, nil)
    }

    // MARK: - Password Strength & Validation
    public static func validatePassword(_ password: String) -> (isValid: Bool, error: String?) {
        guard !password.isEmpty else {
            return (false, "Password cannot be empty.")
        }
        guard password.count >= 8 else {
            return (false, "Password must be at least 8 characters long.")
        }
        let (strength, feedback) = evaluatePasswordStrength(password)
        guard strength.rawValue >= PasswordStrength.weak.rawValue else {
            return (false, feedback)
        }
        return (true, nil)
    }

    public static func evaluatePasswordStrength(_ password: String) -> (strength: PasswordStrength, feedback: String) {
        guard !password.isEmpty else {
            return (.veryWeak, "Password cannot be empty.")
        }

        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil &&
           password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            score += 1
        }
        if password.rangeOfCharacter(from: .decimalDigits) != nil {
            score += 1
        }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':,.<>?/~`")) != nil {
            score += 1
        }

        let strength: PasswordStrength
        let feedback: String

        switch score {
        case 0, 1:
            strength = .veryWeak
            feedback = "Too short. Use at least 8 characters with numbers & symbols."
        case 2:
            strength = .weak
            feedback = "Add uppercase letters, numbers, or special symbols."
        case 3:
            strength = .fair
            feedback = "Good, but adding symbols will make it stronger."
        case 4:
            strength = .strong
            feedback = "Strong enterprise password."
        default:
            strength = .veryStrong
            feedback = "Excellent cryptographic entropy."
        }

        return (strength, feedback)
    }

    // MARK: - TOTP Code Validation (6 Digits)
    public static func validateTotpCode(_ code: String) -> Bool {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count == 6 else { return false }
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleaned))
    }

    // MARK: - EU VAT ID Format Validation
    public static func validateVatId(_ vat: String) -> (isValid: Bool, normalized: String) {
        let normalized = vat.replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: ".", with: "")
                            .replacingOccurrences(of: "-", with: "")
                            .uppercased()

        guard normalized.count >= 4 && normalized.count <= 16 else {
            return (false, normalized)
        }

        let euPrefixes = [
            "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
            "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
            "NL", "PL", "PT", "RO", "SE", "SI", "SK", "XI"
        ]

        let prefix = String(normalized.prefix(2))
        guard euPrefixes.contains(prefix) else {
            return (false, normalized)
        }

        let remaining = String(normalized.dropFirst(2))
        guard !remaining.isEmpty && remaining.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return (false, normalized)
        }

        return (true, normalized)
    }

    // MARK: - SSH Public Key Validation
    public static func validateSshPublicKey(_ key: String) -> (isValid: Bool, keyType: String?, comment: String?) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (false, nil, nil) }

        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2 else { return (false, nil, nil) }

        let type = parts[0]
        let base64Part = parts[1]
        let comment = parts.count > 2 ? parts[2...].joined(separator: " ") : nil

        let validTypes = [
            "ssh-ed25519",
            "ssh-rsa",
            "ecdsa-sha2-nistp256",
            "ecdsa-sha2-nistp384",
            "ecdsa-sha2-nistp521",
            "sk-ssh-ed25519@openssh.com",
            "sk-ecdsa-sha2-nistp256@openssh.com"
        ]

        guard validTypes.contains(type) else {
            return (false, nil, nil)
        }

        // Verify base64 part
        guard Data(base64Encoded: base64Part) != nil else {
            return (false, type, nil)
        }

        return (true, type, comment)
    }
}
