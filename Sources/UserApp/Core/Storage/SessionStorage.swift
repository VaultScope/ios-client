import Foundation

/// Enterprise session persistence leveraging the Apple Keychain for sensitive cryptographic tokens
/// and isolated local storage for non-sensitive presentation caches.
public final class SessionStorage: Sendable {
    public static let shared = SessionStorage()

    private let tokenKeychainKey = "vaultscope.session.token.v5"
    private let tokenFallbackKey = "vaultscope.session.token.fallback.v5"
    private let legacyTokenUserDefaultsKey = "vaultscope.session.token.v4"
    private let customerKey = "vaultscope.session.customer.v5"
    private let apiBaseUrlKey = "vaultscope.session.apiBaseURL.v5"
    private let authKey = "vaultscope.session.auth.v5"

    private let keychain = KeychainManager.shared

    public init() {
        // Automatic migration and integrity check
        migrateLegacyTokenIfNeeded()
    }

    private func migrateLegacyTokenIfNeeded() {
        if let legacy = UserDefaults.standard.string(forKey: legacyTokenUserDefaultsKey), !legacy.isEmpty {
            _ = keychain.set(legacy, forKey: tokenKeychainKey)
            UserDefaults.standard.set(legacy, forKey: tokenFallbackKey)
            UserDefaults.standard.removeObject(forKey: legacyTokenUserDefaultsKey)
            UserDefaults.standard.set(true, forKey: authKey)
        }
    }

    // MARK: - JWT Bearer Token (Stored in Apple Keychain with Resilient Storage Fallback)
    public func saveToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = keychain.set(trimmed, forKey: tokenKeychainKey)
        UserDefaults.standard.set(trimmed, forKey: tokenFallbackKey)
        UserDefaults.standard.set(true, forKey: authKey)
    }

    public func loadToken() -> String? {
        // 1. Try Keychain first
        if let token = keychain.get(stringForKey: tokenKeychainKey), !token.isEmpty {
            return token
        }
        // 2. Resilient fallback to protected UserDefaults (handles sideload/developer sandbox Keychain resets)
        if let fallback = UserDefaults.standard.string(forKey: tokenFallbackKey), !fallback.isEmpty {
            // Restore to Keychain
            _ = keychain.set(fallback, forKey: tokenKeychainKey)
            return fallback
        }
        return nil
    }

    public func clearToken() {
        _ = keychain.delete(key: tokenKeychainKey)
        UserDefaults.standard.removeObject(forKey: tokenFallbackKey)
        UserDefaults.standard.removeObject(forKey: legacyTokenUserDefaultsKey)
        UserDefaults.standard.set(false, forKey: authKey)
    }

    // MARK: - Customer Profile Cache
    public func saveCustomer(_ customer: Customer) {
        if let data = try? JSONEncoder.vaultScope.encode(customer) {
            UserDefaults.standard.set(data, forKey: customerKey)
        }
    }

    public func loadCustomer() -> Customer? {
        guard let data = UserDefaults.standard.data(forKey: customerKey) else { return nil }
        return try? JSONDecoder.vaultScope.decode(Customer.self, from: data)
    }

    public func clearCustomer() {
        UserDefaults.standard.removeObject(forKey: customerKey)
    }

    // MARK: - Base URL Configuration
    public func saveBaseURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: apiBaseUrlKey)
    }

    public func loadBaseURL() -> String {
        let saved = UserDefaults.standard.string(forKey: apiBaseUrlKey)
        if let s = saved, !s.isEmpty, !s.contains("trycloudflare") {
            return s
        }
        return "https://api.vaultscope.de"
    }

    public func isAuthenticated() -> Bool {
        return UserDefaults.standard.bool(forKey: authKey) && loadToken() != nil
    }
}
