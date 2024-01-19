//
//  RadioItem.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 19/01/24.
//

import SwiftUI

struct RadioItem<T>: View {
    let textItem: TextItem<T>
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                Text(LocalizedStringKey(textItem.titleId.description)).font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }
        }
        .foregroundColor(.primary)
        .padding(.bottom,10)
    }
}
