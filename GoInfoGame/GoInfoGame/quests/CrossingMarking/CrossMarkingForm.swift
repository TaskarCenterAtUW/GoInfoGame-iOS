//
//  CrossMarkingForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 19/01/24.
//

import Foundation
import SwiftUI

struct CrossMarkingForm : View,QuestForm{
    var subTitle: String?
    var action: ((CrossingAnswer) -> Void)?
    typealias AnswerClass = CrossingAnswer
    @State private var selectedAnswer: CrossingAnswer?
    @State private var showAlert = false
    let items = [
        TextItem(value: CrossingAnswer.yes, titleId: LocalizedStrings.questCrossingYes.localized),
        TextItem(value: CrossingAnswer.no, titleId: LocalizedStrings.questCrossingNo.localized),
        TextItem(value: CrossingAnswer.prohibited, titleId:  LocalizedStrings.questCrossingProhibited.localized),
    ]
    
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("pedestrian"),
                           title: LocalizedStrings.questCrossingTitle.localized,
                           subtitle: "")
            VStack{
                VStack (alignment: .leading){
                    ForEach(items, id: \.titleId) { item in
                        RadioItem(textItem: item, isSelected: item.value == selectedAnswer) {
                            selectedAnswer = item.value
                            action?(selectedAnswer ?? .no)
                        }
                    }}.padding(.top,10)
                Divider()
                Button {
                    showAlert = true
                } label: {
                    Text(LocalizedStrings.cantSay.localized).foregroundColor(.orange)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("More Questions"))
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }
        .padding()
        
    }
}

