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
    let onToggleOn: (_ status: Bool) -> Void

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
                isEnabled = newValue
                onToggleOn(newValue)
            }
        )) {
            Text(biometricToggleText)
                .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
        }
        .tint(Asset.Colors.accentPink.swiftUIColor)
    }
}

#Preview {
    BiometricToggleView(isEnabled: .constant(true)) { _ in
        
    }
}

