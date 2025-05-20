//
//  BiometricToggleView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 19/05/25.
//

import SwiftUI
import LocalAuthentication

struct BiometricToggleView: View {
    @Binding var isEnabled: Bool
    let onToggleOn: () -> Void

    private var biometricToggleText: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType == .faceID ? "Use Face ID for Login" :
               context.biometryType == .touchID ? "Use Touch ID for Login" :
               "Use Biometric Login"
    }

    var body: some View {
        Toggle(isOn: Binding(
            get: { isEnabled },
            set: { newValue in
                let wasOff = !isEnabled
                isEnabled = newValue
                if newValue && wasOff {
                    // User turned it on manually
                    onToggleOn()
                }
            }
        )) {
            Text(biometricToggleText)
        }
    }
}

