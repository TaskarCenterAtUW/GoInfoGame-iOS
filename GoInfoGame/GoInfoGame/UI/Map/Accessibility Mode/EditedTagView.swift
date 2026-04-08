//
//  TagUpdatedView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 02/12/25.
//

import SwiftUI

struct EditedTagView: View {
    let tagUpdate: (action: UndoItem.TagAction, key: String, value: String)
    var body: some View {
        VStack(alignment: .leading, content: {
            Text(tagUpdate.action.rawValue.uppercased())
                .font(FontFamily.Lato.medium.swiftUIFont(size: 12, relativeTo: .body))
                .foregroundStyle(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .accessibilityLabel(tagUpdate.action.rawValue.uppercased())
            
            VStack {
                HStack {
                    Text(tagUpdate.key)
                        .font(FontFamily.Lato.bold.swiftUIFont(size: 16, relativeTo: .headline))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(tagUpdate.key)
                    Text("= " + tagUpdate.value)
                        .font(FontFamily.Lato.medium.swiftUIFont(size: 16, relativeTo: .headline))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("= " + tagUpdate.value)
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
}

#Preview {
    EditedTagView(tagUpdate: (.added, "Key", "Value"))
}
