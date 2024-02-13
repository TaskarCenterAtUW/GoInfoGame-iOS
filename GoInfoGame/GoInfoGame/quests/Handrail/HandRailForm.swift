//
//  HandRailForm.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import SwiftUI

struct HandRailForm: View, QuestForm {
    var action: ((Bool) -> Void)?
    
    
    typealias AnswerClass = Bool
    
    
    
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("steps_handrail"), title: "Do these steps have handrail?", subtitle: "")
            YesNoView()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }.padding()
    }
}

#Preview {
    HandRailForm()
}
