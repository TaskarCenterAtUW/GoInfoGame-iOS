//
//  TagUpdatedView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 02/12/25.
//

import SwiftUI

struct EditedTagView: View {
    let tagUpdate: (action: UndoItem.TagAction, key: String, value: String)

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, content: {
            Text(tagUpdate.action.rawValue.uppercased())
                .font(FontFamily.Lato.medium.swiftUIFont(size: 12, relativeTo: .body))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(tagUpdate.action.rawValue.uppercased())

            // Side by side, each text only gets ~50% of the row's width; at large
            // accessibility text a long key or value can still need more than that,
            // wrapping mid-word. Stacking them instead gives each the full row width.
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 4) {
                        keyText
                        valueText
                    }
                } else {
                    HStack {
                        keyText
                        valueText
                    }
                }
            }
            .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
        })
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tagUpdate.key) key \(tagUpdate.action.rawValue) with value \(tagUpdate.value)")

    }

    private var keyText: some View {
        Text(tagUpdate.key)
            .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(tagUpdate.key)
    }

    private var valueText: some View {
        Text("= " + tagUpdate.value)
            .font(FontFamily.Lato.medium.swiftUIFont(size: 16, relativeTo: .headline))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("= " + tagUpdate.value)
    }
}

#Preview {
    EditedTagView(tagUpdate: (.added, "Key", "Value"))
}
