//
//  BusStopLitForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct BusStopLitForm: View, QuestForm {
    var action: ((YesNoAnswer) -> Void)?
        
    typealias AnswerClass = YesNoAnswer
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("stop_lit"), title: LocalizedStrings.questBusStopLitTitle.localized, subtitle: "SideWalk")
            YesNoView(action: action).padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }.padding()
    }
}

#Preview {
    BusStopLitForm()
}
