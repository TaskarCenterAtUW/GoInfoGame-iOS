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
    @Published var shouldShowValidationAlert: Bool = false

    @AppStorage("loggedIn") private var loggedIn: Bool = false

    private func validate() -> Bool {
        if username.isEmpty && password.isEmpty {
            errorMessage = "Enter username and password"
        } else if username.isEmpty {
            errorMessage = "Username is required."
        } else if password.isEmpty {
            errorMessage = "Password is required."
        } else {
            return true
        }

        shouldShowValidationAlert = true
        return false
    }

    func performLogin(for environment: APIEnvironment) {
        guard validate() else { return }

        isLoading = true

        SessionManager.shared.performLogin(username: username, password: password, environment: environment) { [weak self] success, error  in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
                self.isLoginSuccess = success
                self.hasLoginFailed = !success
                self.loggedIn = success
            }
        }
    }
}

