//
//  PosmLoginViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

import Foundation

class PosmLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    
    
    func performLogin() {

        let postParams = ["username": username, "password": password]
        
        let postBody  = try? JSONSerialization.data(withJSONObject: postParams)
        
        ApiManager.shared.performRequest(to: .login(postBody!), setupType: .login, modelType: PosmLoginSuccessResponse.self) { result in
            switch result {
            case .success(let posmLoginSuccessResponse):
                let accessToken = posmLoginSuccessResponse.accessToken
                DispatchQueue.main.async {
                    _ = KeychainManager.save(key: "accessToken", data: accessToken)
                    self.isLoggedIn = true
                }
            case .failure(let failure) :
                //TODO:
                print("HANDLE ERROR")
            }
        }
    }
    
//    func prformLogin() {
//        ApiManager.shared.login(username: username, password: password) { result in
//            switch result {
//            case .success(let posmLoginSuccessResponse):
//                let accessToken = posmLoginSuccessResponse.accessToken
//                DispatchQueue.main.async {
//                    _ = KeychainManager.save(key: "accessToken", data: accessToken)
//                    self.isLoggedIn = true
//                }
//              
//            case .failure(let posmLoginErrorResponse):
//                let error = posmLoginErrorResponse.errors.first ?? "An error occured"
//                DispatchQueue.main.async {
//                    self.errorMessage = error
//                }
//             
//            case .error(let string):
//                self.errorMessage = string
//            }
//        }
//    }
}
