//
//  FloatingLabelTextField.swift
//  GoInfoGame
//
//  Created by Prashamsa on 13/08/25.
//

import SwiftUI

struct FloatingLabelTextField: View {
    var title: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Border box
            RoundedRectangle(cornerRadius: 6)
                .stroke(Asset.Colors.borderColorGrayD5DBE6.swiftUIColor, lineWidth: 1)
                .frame(height: 50)
            
            if !text.isEmpty {
                // Floating label
                Text(title)
                    .foregroundColor(Asset.Colors.textFiledTitle83879B.swiftUIColor)
                    .background(.white)
                    .font(FontFamily.Lato.regular.swiftUIFont(fixedSize: 16))
                    .padding(.horizontal, 4)
                    .offset(y: -25)
            }
            
            
            // TextField or SecureField
            if isSecure {
                SecureInputView(title, text: $text)
                    .padding(.horizontal, 8)
                    .frame(height: 50)
            } else {
                TextField(title, text: $text)
                    .padding(.horizontal, 8)
                    .frame(height: 50)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                    .foregroundStyle(Asset.Colors.textFieldText42526E.swiftUIColor)
            }
        }
    }
}
#Preview {
    FloatingLabelTextField(title: "Email", text: .constant(""))
}
