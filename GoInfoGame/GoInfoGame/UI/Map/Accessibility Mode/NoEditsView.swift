//
//  NoEditsView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 04/12/25.
//

import SwiftUI

struct NoEditsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20, content: {
            ZStack(alignment: .center, content: {
                Circle()
                    .frame(width: 106, height: 106)
                    .foregroundColor(Asset.Colors._39C27FGreen.swiftUIColor)
                Image(systemName: "arrow.uturn.backward")
                    .resizable()
                    .foregroundStyle(Color.white)
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(180.0))
                    .frame(width: 60, height: 70)
            })
            .frame(width: 106, height: 106)
            
            Text(L10n.Localizable.noEditsFound)
                .font(FontFamily.Lato.heavy.swiftUIFont(size: 24, relativeTo: .title))
                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(L10n.Localizable.noEditsFound)

            Text(L10n.Localizable.newEditsWillAppearHereWhenAQuestIsAnswered)
                .font(FontFamily.Lato.medium.swiftUIFont(size: 18, relativeTo: .body))
                .foregroundStyle(Asset.Colors._42526ETextFieldText.swiftUIColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(L10n.Localizable.newEditsWillAppearHereWhenAQuestIsAnswered)
        })
    }
}

#Preview {
    NoEditsView()
}
