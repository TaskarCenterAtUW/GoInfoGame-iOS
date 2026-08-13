//
//  SecureInputView.swift
//  GoInfoGame
//
//  Created by Srikanth V on 06/06/25.
//

import SwiftUI

struct SecureInputView: View {
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var placeholder: String
    
    init(_ placeholder: String = "", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecured {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding(.trailing, 32)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .accessibilityLabel(placeholder)

            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Toggle password visibility. " + ( isSecured ? "Show password" : "Hide password" ))
        }
    }
}

#Preview {
    SecureInputView("Password", text: .constant("password"))
}
