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

    func performLogin(username: String, password: String, completion: @escaping (Bool) -> Void) {
        let env = APIConfiguration.shared.environment

        let postParams = ["username": username, "password": password]
        guard let postBody = try? JSONSerialization.data(withJSONObject: postParams) else {
            completion(false)
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
                   _ = KeychainManager.save(.username, value: username, for: env)
                    _ = KeychainManager.save(key: "accessToken", data: response.accessToken)

                    // Store password to keychain only after authenticated by the user
                    self.lastLoginPassword = password

                    self.isLoginSuccessful = true
                    self.hasLoginFailed = false
                    completion(true)

                case .failure(let error):
                    print("Login failed:", error)
                    self.isLoginSuccessful = false
                    self.hasLoginFailed = true
                    completion(false)
                }
            }
        }
    }

    /// Call this after biometric opt-in to save password
    func savePasswordForBiometric() {
        let env = APIConfiguration.shared.environment
        if let password = lastLoginPassword {
            _ = KeychainManager.save(.password, value: password, for: env)
        }
    }

    /// Clears stored session credentials
    func logout(clearBiometricCreds: Bool = false) {
        let env = APIConfiguration.shared.environment

        if clearBiometricCreds {
            _ = KeychainManager.delete(.username, for: env)
            _ = KeychainManager.delete(.password, for: env)
        }

        lastLoginPassword = nil
    }

    func loginWithBiometrics(for environment: APIEnvironment, completion: @escaping (Bool) -> Void) {
        guard let user = KeychainManager.load(.username, for: environment),
              let pass = KeychainManager.load(.password, for: environment) else {
            print("Missing credentials for biometric login")
            completion(false)
            return
        }
        performLogin(username: user, password: pass, completion: completion)
    }

    func canUseBiometricLogin(for environment: APIEnvironment) -> Bool {
        return KeychainManager.load(.username, for: environment) != nil &&
               KeychainManager.load(.password, for: environment) != nil &&
               UserDefaults.standard.bool(forKey: "useBiometricID")
    }
}
