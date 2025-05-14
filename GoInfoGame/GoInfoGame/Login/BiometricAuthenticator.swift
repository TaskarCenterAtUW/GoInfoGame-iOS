//
//  BiometricAuthenticator.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 14/05/25.
//

import LocalAuthentication

class BiometricAuthenticator {
    
    func authenticateUser(completion: @escaping (Result<Bool, Error>) -> Void) {
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
            let reason =  "Login using \(biometricType)"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(true))
                    } else {
                        completion(.failure(authenticationError!))
                    }
                }
            }
        } else {
            completion(.failure(error!))
        }
    }
}
