//
//  ErrorAlert.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import SwiftUI

struct ErrorAlertView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.vertical)
            Button("OK") {
                onDismiss()
            }
            .padding(.bottom)
        }
        .frame(maxWidth: 300)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 20)
        .padding()
    }
}

#Preview {
    ErrorAlertView(message: "This is a custom alert message.", onDismiss: {})
        .padding()
}


