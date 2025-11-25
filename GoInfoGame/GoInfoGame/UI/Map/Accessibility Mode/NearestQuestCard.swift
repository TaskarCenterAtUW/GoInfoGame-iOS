//
//  NearestQuestCard.swift
//  GoInfoGame
//
//  Created by Prashamsa on 25/11/25.
//

import SwiftUI

struct NearestQuestCard: View {
    var body: some View {
        ZStack {
            Asset.Colors.huskyPurple.swiftUIColor
            HStack(spacing: 15, content: {
                ZStack(alignment: .center, content: {
                    Circle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Asset.Colors._39C27FGreen.swiftUIColor)
                    Asset.navigation.swiftUIImage
                        .foregroundStyle(Color.white)
                })
                
                Text("You are 50 meters from \"Sidewalk Quest\", to the Narth east.")
                    .font(FontFamily.Lato.semibold.swiftUIFont(size: 16))
                    .foregroundColor(Color.white)
                    .lineLimit(2)
                    .lineSpacing(2.0)
                Spacer()
            })
            .padding(15)
        }
    }
}

#Preview {
    NearestQuestCard()
}
