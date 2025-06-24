//
//  BiometricAuthenticator.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 14/05/25.
//

import Foundation
import LocalAuthentication

struct BiometricAuthManager {

    enum BiometricAuthResult {
        case success
        case failure(String)
        case unavailable(String)
    }
    
    static func canEvaluateBiometrics() -> Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    static func authenticate(reason: String = "Authenticate to proceed", completion: @escaping (BiometricAuthResult) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        completion(.success)
                    } else {
                        let message = authError?.localizedDescription ?? "Authentication failed."
                        completion(.failure(message))
                    }
                }
            }
        } else {
            let message = error?.localizedDescription ?? "Biometric authentication not available."
            completion(.unavailable(message))
        }
    }

    static func biometricType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static func biometricLabelText() -> String {
        switch biometricType() {
        case .faceID:
            return "Login with Face ID"
        case .touchID:
            return "Login with Touch ID"
        default:
            return "Login with Biometrics"
        }
    }
    
    static func biometricIcon() -> String {
        switch biometricType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "lock"
        default:
            return "lock"
        }
    }
}
