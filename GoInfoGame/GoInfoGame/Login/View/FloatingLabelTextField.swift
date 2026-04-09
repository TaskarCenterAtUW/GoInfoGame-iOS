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
                .stroke(Asset.Colors.d5DBE6BorderColorGray.swiftUIColor, lineWidth: 1)
                .frame(height: 50)
            
            if !text.isEmpty {
                // Floating label
                Text(title)
                    .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                    .background(.white)
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo:    .headline))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(.horizontal, 4)
                    .offset(y: -25)
            }
            
            
            // TextField or SecureField
            if isSecure {
                SecureInputView(title, text: $text)
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .padding(.horizontal, 8)
                    .frame(height: 50)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            } else {
                TextField(title, text: $text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12) // Use padding to create height instead of a fixed frame
                    .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                    .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Text field with title " + title)
    }
}
#Preview {
    FloatingLabelTextField(title: "Email", text: .constant(""))
}
