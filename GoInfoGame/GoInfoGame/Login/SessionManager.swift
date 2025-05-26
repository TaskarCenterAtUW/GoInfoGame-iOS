//
//  SessionManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 14/05/25.
//

import Foundation

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()
    private init() {}

    @Published var isLoginSuccessful: Bool = false
    @Published var hasLoginFailed: Bool = false

    var lastLoginPassword: String?

    func performLogin(username: String, password: String, environment: APIEnvironment, completion: @escaping (Bool, String) -> Void) {
        let userName = KeychainManager.load(.username, for: environment) ?? username
        let postParams = ["username": userName, "password": password]
        guard let postBody = try? JSONSerialization.data(withJSONObject: postParams) else {
            completion(false, "Failed to serialize JSON")
            return
        }

        ApiManager.shared.performRequest(
            to: .login(postBody),
            setupType: .login,
            modelType: PosmLoginSuccessResponse.self
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    _ = KeychainManager.save(.username, value: username, for: environment)
                    _ = KeychainManager.save(key: "accessToken", data: response.accessToken)
                    self.lastLoginPassword = password

                    self.isLoginSuccessful = true
                    self.hasLoginFailed = false
                    completion(true, "")

                case .failure(let error):
                    print("Login failed:", error)
                    self.isLoginSuccessful = false
                    self.hasLoginFailed = true
                    completion(false, "Invalid credentials")
                }
            }
        }
    }

    func savePasswordForBiometric(for environment: APIEnvironment) {
        if let password = lastLoginPassword {
            _ = KeychainManager.save(.password, value: password, for: environment)
        }
        setBiometricEnabled(true, for: environment)
    }

    func logout(environment: APIEnvironment, clearBiometricCreds: Bool = false) {
        if clearBiometricCreds {
            _ = KeychainManager.delete(.username, for: environment)
            _ = KeychainManager.delete(.password, for: environment)
            setBiometricEnabled(false, for: environment)
        }

        lastLoginPassword = nil
    }

    func loginWithBiometrics(for environment: APIEnvironment, completion: @escaping (Bool, String) -> Void) {
        guard let user = KeychainManager.load(.username, for: environment),
              let pass = KeychainManager.load(.password, for: environment) else {
            print(" Missing credentials for biometric login")
            completion(false, "Missing credentials for biometric login")
            return
        }
        performLogin(username: user, password: pass, environment: environment, completion: completion)
    }

    func canUseBiometricLogin(for environment: APIEnvironment) -> Bool {
        return KeychainManager.load(.username, for: environment) != nil &&
               KeychainManager.load(.password, for: environment) != nil &&
               isBiometricEnabled(for: environment)
    }

    func isBiometricEnabled(for env: APIEnvironment) -> Bool {
        return UserDefaults.standard.bool(forKey: biometricKey("useBiometricID", for: env))
    }

    func setBiometricEnabled(_ enabled: Bool, for env: APIEnvironment) {
        UserDefaults.standard.setValue(enabled, forKey: biometricKey("useBiometricID", for: env))
    }

    func hasDeclinedBiometric(for env: APIEnvironment) -> Bool {
        return UserDefaults.standard.bool(forKey: biometricKey("biometricOptInDeclined", for: env))
    }

    func setDeclinedBiometric(_ declined: Bool, for env: APIEnvironment) {
        UserDefaults.standard.setValue(declined, forKey: biometricKey("biometricOptInDeclined", for: env))
    }

    private func biometricKey(_ key: String, for env: APIEnvironment) -> String {
        return "\(key)_\(env.rawValue)"
    }
}
