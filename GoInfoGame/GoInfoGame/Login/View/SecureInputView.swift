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
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
            .accessibilityLabel("Toggle password visibility. " + ( isSecured ? "Show password" : "Hide password" ))
            
            Group {
                if isSecured {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding(.trailing, 32)
            .font(FontFamily.Lato.bold.swiftUIFont(size: 16))
            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
            .accessibilityLabel(placeholder)
        }
    }
}

#Preview {
    SecureInputView("Password", text: .constant("password"))
}
