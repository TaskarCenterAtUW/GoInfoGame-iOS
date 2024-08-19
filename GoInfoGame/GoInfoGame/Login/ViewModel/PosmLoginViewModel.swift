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
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    
    @Published var isLoading = false
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    @Published var isLoginValid: Bool = false
    
    private func validate() {
           errorMessage = ""
           
           if username.isEmpty {
               errorMessage = "Username is required."
           } else if password.isEmpty {
               errorMessage = "Password is required."
           } else if username.isEmpty && password.isEmpty {
               errorMessage = "Enter username and password"
           } else {
               isLoginValid = true
               return
           }
           
           isLoginValid = false
       }
    
    
    func performLogin() {
        
        validate()
        
        if isLoginValid {
            
            isLoading = true
            
            let postParams = ["username": username, "password": password]
            
            _ = KeychainManager.save(key: "username", data: username)
            
            let postBody  = try? JSONSerialization.data(withJSONObject: postParams)
            
            ApiManager.shared.performRequest(to: .login(postBody!), setupType: .login, modelType: PosmLoginSuccessResponse.self) { result in
                switch result {
                case .success(let posmLoginSuccessResponse):
                    let accessToken = posmLoginSuccessResponse.accessToken
                    DispatchQueue.main.async {
                        _ = KeychainManager.save(key: "accessToken", data: accessToken)
                        self.isLoggedIn = true
                        self.loggedIn = true
                        self.isLoading = false
                    }
                case .failure(let failure) :
                    //TODO:
                    DispatchQueue.main.async {
                        self.isLoggedIn = false
                        self.isLoading = false
                    }
                    print("HANDLE ERROR")
                }
            }
        }
    }
}
