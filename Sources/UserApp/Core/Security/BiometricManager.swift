import Foundation
import LocalAuthentication

public enum BiometryType: String, Sendable {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"
    case none = "Passcode"

    public var icon: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.shield.fill"
        }
    }
}

public final class BiometricManager: @unchecked Sendable {
    public static let shared = BiometricManager()

    private let biometricsEnabledKey = "vaultscope.security.biometrics.enabled"

    public init() {}

    public var isBiometricsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: biometricsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: biometricsEnabledKey)
        }
    }

    public var biometryType: BiometryType {
        let context = LAContext()
        var error: NSError?
        // Must call canEvaluatePolicy to populate context.biometryType
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        case .none: return .none
        @unknown default: return .none
        }
    }

    public var canEvaluateBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }
        if let err = error, err.code == LAError.biometryLockout.rawValue {
            return true
        }
        var passError: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &passError)
    }

    public func authenticate(reason: String = "Unlock VaultScope to manage critical cloud infrastructure.") async -> (success: Bool, error: String?) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        let canBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let policy: LAPolicy
        if canBiometrics {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            policy = .deviceOwnerAuthentication
        } else {
            return (false, error?.localizedDescription ?? "Biometric authentication not supported on this device.")
        }

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            return (success, nil)
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel:
                return (false, "Authentication was cancelled.")
            case .userFallback:
                let fallbackContext = LAContext()
                fallbackContext.localizedCancelTitle = "Cancel"
                do {
                    let passcodeSuccess = try await fallbackContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Enter device passcode to unlock VaultScope.")
                    return (passcodeSuccess, nil)
                } catch {
                    return (false, "Passcode entry was cancelled.")
                }
            case .biometryLockout:
                let lockoutContext = LAContext()
                lockoutContext.localizedCancelTitle = "Cancel"
                do {
                    let unlockSuccess = try await lockoutContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Face ID is locked out. Enter device passcode to unlock.")
                    return (unlockSuccess, nil)
                } catch {
                    return (false, "Face ID locked. Device passcode required.")
                }
            case .biometryNotEnrolled:
                return (false, "Face ID is not enrolled on this device. Please set up Face ID in iPhone Settings.")
            default:
                return (false, laError.localizedDescription)
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
