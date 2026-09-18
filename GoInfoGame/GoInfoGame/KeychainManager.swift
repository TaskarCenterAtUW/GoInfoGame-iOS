//
//  KeychainManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 25/03/24.
//


import SwiftUI
import Security

struct KeychainManager {
    
    enum Keys: String {
        case accessToken = "accessToken"
    }
    
    static func save(key: String, data: String) -> Bool {
        #if DEBUG
        // A UI test binary is routinely built with CODE_SIGNING_ALLOWED=NO (this project's
        // own CI does), which leaves the app with no entitlements at all - SecItemAdd then
        // fails outright with errSecMissingEntitlement (-34018), since a Keychain access
        // group can't be resolved for an unsigned binary. Confirmed directly: seeding an
        // accessToken for a UI test (UITestStubs.seedLoggedInAndLandOnWorkspaces) got
        // exactly that status back, with save() silently returning false and every later
        // load() returning nil - which left InitialViewModel.fetchWorkspacesList() unable
        // to find an accessToken, so it never even attempted the network request, and the
        // screen sat on its "Loading workspaces..." text forever. Falling back to
        // UserDefaults only when UITestRuntime.isActive keeps this invisible to any signed
        // build (Release, or an ordinarily-signed Debug run) - those keep using the real
        // Keychain, unchanged.
        if UITestRuntime.isActive {
            UserDefaults.standard.set(data, forKey: uiTestFallbackKey(for: key))
            return true
        }
        #endif

        guard let data = data.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            NSLog("[KeychainManager] SecItemAdd failed for key=%@ status=%d", key, status)
        }
        return status == errSecSuccess
    }

    static func load(key: String) -> String? {
        #if DEBUG
        if UITestRuntime.isActive {
            return UserDefaults.standard.string(forKey: uiTestFallbackKey(for: key))
        }
        #endif

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
            let data = dataTypeRef as? Data,
            let result = String(data: data, encoding: .utf8) else {
                return nil
        }

        return result
    }

    static func delete(key: String) -> Bool {
        #if DEBUG
        if UITestRuntime.isActive {
            UserDefaults.standard.removeObject(forKey: uiTestFallbackKey(for: key))
            return true
        }
        #endif

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    #if DEBUG
    /// Namespaced so this can never collide with a real app UserDefaults key, and so
    /// UITestStubs.resetStateIfNeeded()'s removePersistentDomain wipe (it clears the whole
    /// domain) also clears these between tests same as it does everything else.
    private static func uiTestFallbackKey(for key: String) -> String {
        "uitest_keychain_fallback_\(key)"
    }
    #endif
}

extension KeychainManager {
    enum Key: String {
        case username
        case password

        func namespaced(for environment: APIEnvironment) -> String {
            return "\(rawValue)_\(environment.rawValue)"
        }
    }

    static func save(_ key: Key, value: String, for environment: APIEnvironment) -> Bool {
        let namespacedKey = key.namespaced(for: environment)
        return save(key: namespacedKey, data: value)
    }

    static func load(_ key: Key, for environment: APIEnvironment) -> String? {
        let namespacedKey = key.namespaced(for: environment)
        return load(key: namespacedKey)
    }

    static func delete(_ key: Key, for environment: APIEnvironment) -> Bool {
        let namespacedKey = key.namespaced(for: environment)
        return delete(key: namespacedKey)
    }
}
