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

            // Stays content-sized (matching the original compact dialog look) as long as it
            // fits; only falls back to a scrolling version if large accessibility text makes
            // the content taller than the available space, instead of clipping/overflowing.
            ViewThatFits(in: .vertical) {
                dialogContent
                ScrollView {
                    dialogContent
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(40)

            if viewModel.isLoading {
                ProgressView("Authenticating...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3).ignoresSafeArea())
            }
        }
    }

    private var dialogContent: some View {
        VStack(spacing: 16) {
            Text("Enable Biometric Login")
                .font(.headline)
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)

            SecureField("Enter your password", text: $viewModel.password)
                .textContentType(.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }

            Button("Continue") {
                handleContinue()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Asset.Colors.huskyPurple.swiftUIColor)
            .foregroundColor(.white)
            .cornerRadius(8)

            Button("Cancel") {
                onCancel()
            }
            .frame(minHeight: 44)
            .foregroundStyle(Asset.Colors.accentPink.swiftUIColor)
        }
        .padding()
    }

    private func handleContinue() {
        let environment = APIConfiguration.shared.environment
        let username = SessionManager.shared.username ?? ""

        viewModel.performBiometricEnrollment(
            username: username,
            environment: environment,
            onSuccess: {
                onSuccess()
            },
            onFailure: { error in
                viewModel.errorMessage = error
                onFailure(error)
            }
        )
    }
}




#Preview {
    PasswordAuthenticationPopupView(viewModel: PasswordAuthenticationViewModel()) {
            
    } onCancel: {
    
    } onFailure: { _ in
        
    }

}
