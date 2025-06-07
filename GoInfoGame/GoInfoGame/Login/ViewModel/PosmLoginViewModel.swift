//
//  PosmLoginViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/08/24.
//

import Foundation
import SwiftUI

enum LoginContent: Equatable {
    case login
    
    var loadingMessage: String {
        switch self {
        case .login: "Logging in..."
        }
    }
}

typealias LoginState = ViewModelState<LoginContent>

final class PosmLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""

    @Published var errorMessage: String?
    
    @AppStorage("loggedIn") private var loggedIn: Bool = false
        
    @Published var state: LoginState = .idle
    
    private let api: TDEIAPIProtocol
    private let sessionManager: SessionManager
    
    @Published var route: NavigationRoute?
    
    init(api: TDEIAPIProtocol = TDEIAPIManager.shared, sessionManager: SessionManager = .shared, state: LoginState = .idle) {
        self.api = api
        self.sessionManager = sessionManager
        self.state = state
    }

    // Removed completion handler from performLogin for now
    func performLogin(with environment: AppEnv) {
        guard !username.isEmpty, !password.isEmpty else {
            state = .error("Username and Password cannot be empty.")
            return
        }
        state = .loading(.login)
        sessionManager.performLogin(username: username, password: password, environment: environment) { [weak self] success, error in
            if success {
                self?.state = .loaded(.login)
                self?.route = .workspace
                self?.loggedIn = true
            } else {
                self?.state = .error(error)
            }
        }
    }
}
