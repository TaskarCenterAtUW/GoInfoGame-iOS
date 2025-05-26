//
//  PosmLoginViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

import Foundation
import SwiftUI

final class PosmLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""

    @Published var errorMessage: String?
        
    @AppStorage("loggedIn") private var loggedIn: Bool = false
        
    @Published var state: ViewModelState = .idle
    
    private let api: TDEIAPIProtocol
    
    @Published var route: NavigationRoute?
    
    init(api: TDEIAPIProtocol = TDEIAPIManager.shared, state: ViewModelState = .idle) {
        self.api = api
        self.state = state
    }

    func performLogin() {
        
            guard !username.isEmpty, !password.isEmpty else {
                state = .error("Username and Password cannot be empty.")
                return
            }
            state = .loading
                        
            _ = KeychainManager.save(key: "username", data: username)
                        
            api.login(username: username, password: password) { [weak self] result in
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
                        self?.state = .loaded
                        self?.route = .workspace
                        self?.loggedIn = true
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.state = .error(error.localizedDescription)
                    }
                }
            }
    }
}
