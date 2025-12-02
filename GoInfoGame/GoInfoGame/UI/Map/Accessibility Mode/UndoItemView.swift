//
//  undoItemView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/25.
//

import SwiftUI

struct UndoItemView: View {
    let undoItem: UndoItem
    var body: some View {
        VStack(alignment: .leading, content: {
            Text(undoItem.timestamp.formatted(date: .omitted, time: .shortened))
                .font(FontFamily.Lato.medium.swiftUIFont(fixedSize: 14))
            Text(L10n.Localizable.type + ": " + (undoItem.questType ?? "Not Avilable"))
                .font(FontFamily.Lato.bold.swiftUIFont(fixedSize: 16))
        })
        .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .overlay {
            RoundedRectangle(cornerRadius: 10.0)
                .stroke(Asset.Colors._42526ETextFieldText.swiftUIColor, lineWidth: 1)
                .foregroundStyle(Color.clear)
        }
    }
}

#Preview {
    UndoItemView(undoItem: UndoItem(elementId: 101, type: .node, changedKeys: ["key1", "Key2"], id: "402322", timestamp: Date(), questType: "Sidewalk", tags: [(.added, "Key1", "Value 1"), (.modified, "Key2", "Value 2")], iconName: "sidewalk"))
}
