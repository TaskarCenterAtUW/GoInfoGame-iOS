//
//  NoQuestsNearView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 27/11/25.
//

import SwiftUI

struct NoQuestsNearView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20, content: {
            ZStack(alignment: .center, content: {
                Circle()
                    .frame(width: 106, height: 106)
                    .foregroundColor(Asset.Colors._39C27FGreen.swiftUIColor)
                Image(systemName: "drop")
                    .resizable()
                    .foregroundStyle(Color.white)
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(180.0))
                    .frame(width: 60, height: 70)
                
                Image(systemName: "questionmark")
                    .resizable()
                    .foregroundStyle(Color.white)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 28)
                    .bold()

            })
            .frame(width: 106, height: 106)
            
            Text(L10n.Localizable.noQuestsFound)
                .font(FontFamily.Lato.heavy.swiftUIFont(size: 24, relativeTo: .title))
                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: false)
                .accessibilityLabel(L10n.Localizable.noQuestsFound)
            
            Text(L10n.Localizable.tryMovingToADifferentLocationToDiscoverMoreQuests)
                .font(FontFamily.Lato.medium.swiftUIFont(size: 18, relativeTo: .subheadline))
                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .accessibilityLabel(L10n.Localizable.tryMovingToADifferentLocationToDiscoverMoreQuests)
        })
    }
}

#Preview {
    NoQuestsNearView()
}
