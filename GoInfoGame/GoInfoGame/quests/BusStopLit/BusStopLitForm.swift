//
//  BusStopLitForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct BusStopLitForm: View, QuestForm {
    var action: ((Bool) -> Void)?
    
    func applyAnswer(answer: Bool) {
    }
    typealias AnswerClass = Bool
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("stop_lit"), title: LocalizedStrings.questBusStopLitTitle.localized, subtitle: "SideWalk")
            YesNoView().padding(10)
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
