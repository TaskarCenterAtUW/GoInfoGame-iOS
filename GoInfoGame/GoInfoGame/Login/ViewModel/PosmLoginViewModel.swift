//
//  PosmLoginViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

import Foundation
import SwiftUI

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
            
            _ = KeychainManager.save(key: "username", data: username)
            
            let postBody  = try? JSONSerialization.data(withJSONObject: postParams)
            
            TDEIAPIManager.shared.login(username: username, password: password) { [weak self] result in
                switch result {
                case .success(let posmLoginSuccessResponse):
                    let accessToken = posmLoginSuccessResponse.accessToken
                    let refreshToken = posmLoginSuccessResponse.refreshToken
                    DispatchQueue.main.async {
                        _ = KeychainManager.save(key: "accessToken", data: accessToken)
                        _ = KeychainManager.save(key: "refreshToken", data: refreshToken)
                        UserDefaults.standard.setValue(posmLoginSuccessResponse.expiresIn, forKey: "accessToken_expire_in")
                        UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: "accessToken_Generate")
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            appDelegate.validateAccessToken()
                        }
                        self?.hasLoginFailed = false
                        self?.loggedIn = true
                        self?.isLoading = false
                        self?.isLoginSuccess = true
                    }
                case .failure(_) :
                    DispatchQueue.main.async {
                        self?.hasLoginFailed = true
                        self?.isLoading = false
                    }
                }
            }
        }
    }
}
