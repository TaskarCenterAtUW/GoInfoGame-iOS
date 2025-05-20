//
//  PasswordAuthenticationPopupView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 15/05/25.
//

import SwiftUI
import LocalAuthentication

struct PasswordAuthenticationPopupView: View {
    @ObservedObject var viewModel: PasswordAuthenticationViewModel
    let onSuccess: () -> Void
    let onCancel: () -> Void
    let onFailure: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Enable Biometric Login")
                    .font(.headline)

                SecureField("Enter your password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("Continue") {
                    handleContinue()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Cancel") {
                    onCancel()
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .padding(40)

            if viewModel.isLoading {
                ProgressView("Logging in...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3).ignoresSafeArea())
            }
        }
    }

    private func handleContinue() {
        let environment = APIConfiguration.shared.environment
        let username = KeychainManager.load(.username, for: environment) ?? ""

        viewModel.performBiometricEnrollment(
            username: username,
            environment: environment,
            onSuccess: {
                onSuccess()
            },
            onFailure: { error in
                // Nothing here; viewModel will handle errorMessage
                viewModel.errorMessage = error
                onFailure(error)
            }
        )
    }
}




//#Preview {
//    PasswordAuthenticationPopupView(
//        viewModel: <#PasswordAuthenticationViewModel#>, onSuccess: {
//            print("Biometric setup successful")
//        },
//        onCancel: {
//            print("Biometric setup cancelled")
//        }
//    )
//}
