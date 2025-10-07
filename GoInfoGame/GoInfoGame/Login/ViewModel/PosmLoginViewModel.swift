//
//  PosmLoginViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

import Foundation
import SwiftUI
import LocalAuthentication

class PosmLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var hasLoginFailed: Bool = false
    @Published var loginFailedMessage: String? = nil
    @Published var isLoginSuccess: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var shouldShowValidationAlert: Bool = false
    @Published var showBiometricPrompt = false

    @AppStorage("loggedIn") private var loggedIn: Bool = false

    private func validate() -> Bool {
        if username.isEmpty && password.isEmpty {
            errorMessage = "Enter username and password"
        } else if username.isEmpty {
            errorMessage = "Username is required."
        } else if password.isEmpty {
            errorMessage = "Password is required."
        } else {
            errorMessage = nil
            return true
        }

        shouldShowValidationAlert = true
        return false
    }

    func performLogin(for environment: APIEnvironment) {
        guard validate() else { return }

        isLoading = true

        SessionManager.shared.performLogin(username: username, password: password, environment: environment) { [weak self] success, error  in
            guard let self = self else { return }

            self.isLoading = false
            self.loggedIn = success
            let env = APIConfiguration.shared.environment
            if success {
                if canEvaluateBiometrics() {
                    if !SessionManager.shared.hasDeclinedBiometric(for: env) {
                        if !SessionManager.shared.isBiometricEnabled(for: env) ||
                            (SessionManager.shared.isBiometricEnabled(for: env) && self.username != KeychainManager.load(.username, for: env)){
                            _ = KeychainManager.save(.username, value: username, for: env)
                            self.showBiometricPrompt = true
                            return
                        }
                    }
                }
                _ = KeychainManager.save(.username, value: username, for: env)
                self.isLoginSuccess = success
            } else {
                self.hasLoginFailed = !success
            }
        }
    }
    
    private func canEvaluateBiometrics() -> Bool {
        BiometricAuthManager.canEvaluateBiometrics()
    }
    
    func enableBiometrics(enable: Bool) {
        guard self.loggedIn else {
            return
        }
        if enable, canEvaluateBiometrics() {
            BiometricAuthManager.authenticate { [weak self] result in
                switch result {
                    case .success:
                    if let username = self?.username,
                       let password = self?.password {
                        let env = APIConfiguration.shared.environment
                        _ = KeychainManager.save(.username, value: username, for: env)
                        _ = KeychainManager.save(.password, value: password, for: env)
                        SessionManager.shared.setBiometricEnabled(true, for: env)
                    }
                    
                case .failure(let message):
                    print(message)
                case .unavailable(let message):
                    print(message)
                }
                self?.isLoginSuccess = true
            }
        } else {
            SessionManager.shared.setDeclinedBiometric(true, for: APIConfiguration.shared.environment)
            self.isLoginSuccess = true
        }
    }
    
    func loginWithRefreshToken(refreshToken: String) {
        isLoading = true
        
        TokenRefresher.shared.refreshToken(refreshToken: refreshToken) { [weak self] result, error  in
            DispatchQueue.main.async { [weak self, result, error] in
                self?.isLoading = false
                
                self?.loggedIn = result
                self?.isLoginSuccess = result
                self?.hasLoginFailed = !result
                if let _ = error {
                    self?.loginFailedMessage = L10n.Localizable.invalidCredentials
                }
                
                guard result,
                      let accessToken = KeychainManager.load(key: "accessToken"),
                      let email = self?.emailIDfromJWT(token: accessToken) else {
                    return
                }
                _ = KeychainManager.save(.username, value: email, for: APIConfiguration.shared.environment)
            }
        }
    }
    
    private func emailIDfromJWT(token: String) -> String? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            debugPrint("Invalid JWT format.")
            return nil
        }
        
        let payloadSegment = segments[1]
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let remainingLength = base64.count % 4
        if remainingLength > 0 {
            let padding = String(repeating: "=", count: 4 - remainingLength)
            base64 = base64 + padding
        }
        
        guard let data = Data(base64Encoded: base64) else {
            debugPrint("Could not Base64URL decode the payload.")
            return nil
        }
        
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                debugPrint("Could not parse payload data as JSON object.")
                return nil
            }
            
            if let email = jsonObject["email"] as? String {
                return email
            } else {
                debugPrint("Email claim not found in JWT payload, or is not a String.")
                return nil
            }
        } catch {
            debugPrint("Error parsing JSON payload: \(error)")
            return nil
        }
    }
}

