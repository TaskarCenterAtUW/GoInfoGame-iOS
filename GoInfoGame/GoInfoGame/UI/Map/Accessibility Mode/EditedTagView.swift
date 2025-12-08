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
                .font(FontFamily.Lato.medium.swiftUIFont(fixedSize: 12))
                .foregroundStyle(Asset.Colors.a2A2A2Gray.swiftUIColor)
            HStack {
                Text(tagUpdate.key)
                    .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
                Text("= " + tagUpdate.value)
                    .font(FontFamily.Lato.medium.swiftUIFont(fixedSize: 16))
            }
            .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    EditedTagView(tagUpdate: (.added, "Key", "Value"))
}
