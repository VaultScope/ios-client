import Foundation

/// Enterprise session persistence leveraging the Apple Keychain for sensitive cryptographic tokens
/// and isolated local storage for non-sensitive presentation caches.
public final class SessionStorage: Sendable {
    public static let shared = SessionStorage()

    private let tokenKeychainKey = "vaultscope.session.token.v5"
    private let legacyTokenUserDefaultsKey = "vaultscope.session.token.v4"
    private let customerKey = "vaultscope.session.customer.v5"
    private let apiBaseUrlKey = "vaultscope.session.apiBaseURL.v5"
    private let authKey = "vaultscope.session.auth.v5"

    private let keychain = KeychainManager.shared

    public init() {
        // Automatic one-time migration from legacy UserDefaults to Keychain
        migrateLegacyTokenIfNeeded()
    }

    private func migrateLegacyTokenIfNeeded() {
        if let legacy = UserDefaults.standard.string(forKey: legacyTokenUserDefaultsKey), !legacy.isEmpty {
            keychain.set(legacy, forKey: tokenKeychainKey)
            UserDefaults.standard.removeObject(forKey: legacyTokenUserDefaultsKey)
            UserDefaults.standard.set(true, forKey: authKey)
        }
    }

    // MARK: - JWT Bearer Token (Stored in Apple Keychain)
    public func saveToken(_ token: String) {
        keychain.set(token, forKey: tokenKeychainKey)
        UserDefaults.standard.set(true, forKey: authKey)
    }

    public func loadToken() -> String? {
        if let token = keychain.get(stringForKey: tokenKeychainKey), !token.isEmpty {
            return token
        }
        return nil
    }

    public func clearToken() {
        keychain.delete(key: tokenKeychainKey)
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
