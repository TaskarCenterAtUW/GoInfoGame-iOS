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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility text sizes the floating label grows tall enough that a fixed
        // offset above the border no longer clears the field below it, so the label is
        // stacked above the field instead of overlaid on the border in that case.
        if dynamicTypeSize.isAccessibilitySize {
            accessibilityLayout
        } else {
            standardLayout
        }
    }

    private var fieldContent: some View {
        Group {
            if isSecure {
                SecureInputView(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .accessibilityLabel(title)
            }
        }
        .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
        .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 12) // Use padding to create height instead of a fixed frame
        .multilineTextAlignment(.leading)
        .lineLimit(nil)
    }

    private var standardLayout: some View {
        ZStack(alignment: .topLeading) {
            // Border box - grows to fit the field instead of clipping at large text sizes
            RoundedRectangle(cornerRadius: 6)
                .stroke(Asset.Colors.d5DBE6BorderColorGray.swiftUIColor, lineWidth: 1)
                .frame(minHeight: 50)
                .accessibilityHidden(true)

            fieldContent

            if !text.isEmpty {
                // Floating label - anchored to the top edge so it stays put as the field grows
                Text(title)
                    .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                    .background(.white)
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .offset(x: 8, y: -10)
                    .accessibilityHidden(true)
            }
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !text.isEmpty {
                Text(title)
                    .foregroundColor(Asset.Colors._83879BTextFiledTitle.swiftUIColor)
                    .font(FontFamily.Lato.regular.swiftUIFont(size: 16, relativeTo: .headline))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .accessibilityHidden(true)
            }
            fieldContent
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Asset.Colors.d5DBE6BorderColorGray.swiftUIColor, lineWidth: 1)
                        .accessibilityHidden(true)
                )
        }
    }
}
#Preview {
    FloatingLabelTextField(title: "Email", text: .constant(""))
}
