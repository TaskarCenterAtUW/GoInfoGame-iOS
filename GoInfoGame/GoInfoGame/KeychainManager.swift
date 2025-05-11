//
//  KeychainManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 25/03/24.
//


import SwiftUI
import Security

struct KeychainManager {
    
    static func save(key: String, data: String) -> Bool {
        guard let data = data.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func load(key: String) -> String? {
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    static func loadSessionValue(_ key: String) -> String? {
        let env = APIConfiguration.shared.environment

        switch key {
        case "username":
            return load(.username, for: env)
        case "password":
            return load(.password, for: env)
        case "accessToken":
            return load(.accessToken, for: env)
        default:
            return load(key: key) // Fallback to loading from the generic keychain
        }
    }
}


extension KeychainManager {
    
    enum Key: String {
        case username
        case password
        case accessToken

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
