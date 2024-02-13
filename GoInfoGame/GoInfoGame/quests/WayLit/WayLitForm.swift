//
//  WayLitForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct WayLitForm: View, QuestForm {
    var action: ((YesNoAnswer) -> Void)?
    typealias AnswerClass = YesNoAnswer
    @State private var shouldShowAreYouSureAlert = false
    @State private var answer: YesNoAnswer = .unknown
    var action: ((AnswerClass) -> Void)?
    
    
    typealias AnswerClass = WayLitOrIsStepsAnswer
    
    
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("add_way_lit"), title: LocalizedStrings.questLitTitle.localized, subtitle: "SideWalk")
            YesNoView(action: action)
             .background(
            YesNoView { selectedAnswer in
                self.answer = selectedAnswer
                // Apply answer as needed
                switch answer {
                case .no :
                    print("Not lit")
                    // present are you sure alert
                    self.shouldShowAreYouSureAlert = true
                case .yes :
                    print("Lit")
                    self.shouldShowAreYouSureAlert = true
                case .other:
                    print("Present other options")
                case .unknown:
                    print("Dont know yet.")
                }
            } .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }.padding()
            .overlay(
                Group {
                    if shouldShowAreYouSureAlert {
                        CustomSureAlert(onCancel: {
                            self.shouldShowAreYouSureAlert = false
                        }, onConfirm: {
                            self.shouldShowAreYouSureAlert = false
                            //TODO: Submit answer
                            
                        })

                    }
                }
            )
    }
}

#Preview {
    WayLitForm()
}
