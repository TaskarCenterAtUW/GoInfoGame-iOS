//
//  SessionManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 14/05/25.
//

import Foundation

final class SessionManager: ObservableObject {
    static let shared = SessionManager()
    private let api: TDEIAPIProtocol
    
    init(api: TDEIAPIProtocol = TDEIAPIManager.shared) {
        self.api = api
    }

    var lastLoginPassword: String?

    func performLogin(username: String, password: String, environment: AppEnv, completion: @escaping (Bool, String) -> Void) {
        let userName = KeychainManager.load(.username, for: environment) ?? username
        guard !userName.isEmpty, !password.isEmpty else {
            completion(false, "Username and Password cannot be empty.")
            return
        }
        
        _ = KeychainManager.save(.username, value: userName, for: environment)
        
        api.login(username: userName, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    _ = KeychainManager.save(key: "accessToken", data: response.accessToken)
                    _ = KeychainManager.save(key: "refreshToken", data: response.refreshToken)
                    UserDefaults.standard.setValue(response.expiresIn, forKey: "accessToken_expire_in")
                    UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
                    self?.lastLoginPassword = password
                    AuthSessionManager.shared.validateAccessToken()
                    completion(true, "")
                case .failure(let error):
                    print("Login failed:", error)
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    func savePasswordForBiometric(for environment: AppEnv) {
        if let password = lastLoginPassword {
            _ = KeychainManager.save(.password, value: password, for: environment)
        }
        setBiometricEnabled(true, for: environment)
    }

    func logout(environment: AppEnv, clearBiometricCreds: Bool = false) {
        if clearBiometricCreds {
            _ = KeychainManager.delete(.username, for: environment)
            _ = KeychainManager.delete(.password, for: environment)
            setBiometricEnabled(false, for: environment)
        }

        lastLoginPassword = nil
    }

    func loginWithBiometrics(for environment: AppEnv, completion: @escaping (Bool, String) -> Void) {
        guard let user = KeychainManager.load(.username, for: environment),
              let pass = KeychainManager.load(.password, for: environment) else {
            print(" Missing credentials for biometric login")
            completion(false, "Missing credentials for biometric login")
            return
        }
        performLogin(username: user, password: pass, environment: environment, completion: completion)
    }

    func canUseBiometricLogin(for environment: AppEnv) -> Bool {
        return KeychainManager.load(.username, for: environment) != nil &&
               KeychainManager.load(.password, for: environment) != nil &&
               isBiometricEnabled(for: environment)
    }

    func isBiometricEnabled(for env: AppEnv) -> Bool {
        return UserDefaults.standard.bool(forKey: biometricKey("useBiometricID", for: env))
    }

    func setBiometricEnabled(_ enabled: Bool, for env: AppEnv) {
        UserDefaults.standard.setValue(enabled, forKey: biometricKey("useBiometricID", for: env))
    }

    func hasDeclinedBiometric(for env: AppEnv) -> Bool {
        return UserDefaults.standard.bool(forKey: biometricKey("biometricOptInDeclined", for: env))
    }

    func setDeclinedBiometric(_ declined: Bool, for env: AppEnv) {
        UserDefaults.standard.setValue(declined, forKey: biometricKey("biometricOptInDeclined", for: env))
    }

    private func biometricKey(_ key: String, for env: AppEnv) -> String {
        return "\(key)_\(env.rawValue)"
    }
}
