//
//  FaceID.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 11/05/25.
//
import LocalAuthentication

class BiometricAuthenticator {
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let biometricType: String
            switch context.biometryType {
            case .faceID:
                biometricType = "Face ID"
            case .touchID:
                biometricType = "Touch ID"
            default:
                biometricType = "biometrics"
            }

            let reason = "Login using \(biometricType)"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError?.localizedDescription)
                }
            }
        } else {
            completion(false, error?.localizedDescription ?? "Biometric authentication is not available.")
        }
    }
}
