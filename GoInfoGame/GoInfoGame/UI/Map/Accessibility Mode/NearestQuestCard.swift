//
//  NearestQuestCard.swift
//  GoInfoGame
//
//  Created by Prashamsa on 25/11/25.
//

import SwiftUI
import CoreLocation

struct NearestQuestCard: View {
    let quest: AccessibilityModeViewModel.AccessibilityQuest
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
                
                
                Text("You are \(Int(quest.distance.rounded())) meters from \"\(quest.questType)\", to the \(quest.direction).")
                    .font(FontFamily.Lato.semibold.swiftUIFont(size: 16, relativeTo: .body))
                    .foregroundColor(Color.white)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .lineSpacing(2.0)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("You are \(Int(quest.distance.rounded())) meters from \"\(quest.questType)\", to the \(quest.direction).")
                Spacer()
            })
            .padding(15)
        }
    }
}

#Preview {
    NearestQuestCard(quest: AccessibilityModeViewModel.AccessibilityQuest(distance: 0.0, questType: "Side Walk", direction: "Unknown", quest: DisplayUnitWithCoordinate(displayUnit: DisplayUnit(title: "", description: "", id: "", parent: nil, sheetSize: nil), coordinateInfo: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), id: 1, isHidden: false)))
}
