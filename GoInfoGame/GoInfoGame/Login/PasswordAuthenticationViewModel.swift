//
//  PasswordAuthenticationViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/05/25.
//
import Foundation

@MainActor
class PasswordAuthenticationViewModel: ObservableObject {
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    func performBiometricEnrollment(
        username: String,
        environment: APIEnvironment,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping () -> Void
    ) {
        isLoading = true
        errorMessage = ""
        
        SessionManager.shared.performLogin(username: username, password: password, environment: environment) { success in
            DispatchQueue.main.async {
                if success {
                    BiometricAuthManager.authenticate(reason: "Enable biometric login") { result in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            switch result {
                            case .success:
                                SessionManager.shared.lastLoginPassword = self.password
                                SessionManager.shared.savePasswordForBiometric(for: environment)
                                onSuccess()
                            case .failure(let msg), .unavailable(let msg):
                                self.errorMessage = msg
                                onFailure()
                            }
                        }
                    }
                } else {
                    self.isLoading = false
                    self.errorMessage = "Invalid username or password."
                    onFailure()
                }
            }
        }
    }
}
