//
//  PosmLoginViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

import Foundation
import SwiftUI
import LocalAuthentication

@MainActor
class PosmLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var hasLoginFailed: Bool = false
    @Published var isLoginSuccess: Bool = false
    @Published var errorMessage: String?
    
    @Published var isLoading = false
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @Published var shouldShowValidationAlert: Bool = false
    
    private let biometricAuthenticator = BiometricAuthenticator()
    @Published var biometricIDErrorMessage: String?
    @Published var shouldShowBiometricErrorAlert: Bool = false
    
    private func validate() {
           errorMessage = ""
           
           if username.isEmpty {
               errorMessage = "Username is required."
               shouldShowValidationAlert = true
               return
           } else if password.isEmpty {
               errorMessage = "Password is required."
               shouldShowValidationAlert = true
               return
           } else if username.isEmpty && password.isEmpty {
               errorMessage = "Enter username and password"
               shouldShowValidationAlert = true
               return
           }
        shouldShowValidationAlert = false
       }
    
    
    func performLogin() {
        
        validate()
        
        if !shouldShowValidationAlert {
            
            isLoading = true
            
            let postParams = ["username": username, "password": password]
            
          //  _ = KeychainManager.save(key: "username", data: username)
            
            let postBody  = try? JSONSerialization.data(withJSONObject: postParams)
            
            let env = APIConfiguration.shared.environment
            
            ApiManager.shared.performRequest(to: .login(postBody!), setupType: .login, modelType: PosmLoginSuccessResponse.self) { result in
                switch result {
                case .success(let posmLoginSuccessResponse):
                    let accessToken = posmLoginSuccessResponse.accessToken
                    let refreshToken = posmLoginSuccessResponse.refreshToken
                    DispatchQueue.main.async {
                            _ = KeychainManager.save(.username, value: self.username, for: env)
                            _ =  KeychainManager.save(.password, value: self.password, for: env)
                            _ = KeychainManager.save(.accessToken, value: accessToken, for: env)
                            _ = KeychainManager.save(key: "refreshToken", data: refreshToken)
                        UserDefaults.standard.setValue(posmLoginSuccessResponse.expiresIn, forKey: "accessToken_expire_in")
                        UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            appDelegate.validateAccessToken()
                        }
                        self.hasLoginFailed = false
                        self.loggedIn = true
                        self.isLoading = false
                        self.isLoginSuccess = true
                    }
                case .failure(let failure) :
                    //TODO:
                    DispatchQueue.main.async {
                        self.hasLoginFailed = true
                        self.isLoading = false
                    }
                    print("HANDLE ERROR")
                }
            }
        }
    }
    
    func loginWithBiometricID() {
        
        let env = APIConfiguration.shared.environment
        
        biometricAuthenticator.authenticate { [weak self] success, error in
            guard let self = self else { return }

            if success {
                if let savedUsername = KeychainManager.load(.username, for: env),
                   let savedPassword = KeychainManager.load(.password, for: env)  {
                    
                    self.username = savedUsername
                    self.password = savedPassword

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.performLogin()
                    }
                } else {
                    self.biometricIDErrorMessage = "Saved credentials not found. Please login manually."
                    self.shouldShowBiometricErrorAlert = true
                }
            } else {
                if let error = error?.lowercased() {
                    if error.contains("canceled") {
                        self.biometricIDErrorMessage = "Biometric ID was canceled."
                    } else if error.contains("not available") || error.contains("not enrolled") {
                        self.biometricIDErrorMessage = "Biometric ID is not available or not set up."
                    } else {
                        self.biometricIDErrorMessage = "Authentication failed: \(error)"
                    }
                } else {
                    self.biometricIDErrorMessage = "An unknown error occurred. Please try again."
                }
                self.shouldShowBiometricErrorAlert = true
            }
        }
    }
}
