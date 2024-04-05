//
//  CrossMarkingForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 19/01/24.
//

import Foundation
import SwiftUI

struct CrossMarkingForm : View,QuestForm{
    var action: ((CrossingAnswer) -> Void)?
    typealias AnswerClass = CrossingAnswer
    @State private var selectedAnswer =  CrossingAnswer.none;
    @State private var showAlert = false
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var contextualInfo: ContextualInfo
    
    let items = [
        TextItem(value: CrossingAnswer.yes, titleId: LocalizedStrings.questCrossingYes.localized),
        TextItem(value: CrossingAnswer.no, titleId: LocalizedStrings.questCrossingNo.localized),
    ]
    
    var body: some View {
        VStack{
            DismissButtonView {
                withAnimation {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            QuestionHeader(icon: Image("pedestrian"),
                           title: LocalizedStrings.questCrossingTitle.localized,
                           contextualInfo: contextualInfo.info)
            VStack{
                VStack (alignment: .leading){
                    ForEach(items, id: \.titleId) { item in
                        RadioItem(textItem: item, isSelected: item.value == selectedAnswer) {
                            selectedAnswer = item.value
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top,5)
                        .padding(.bottom,5)
                    }}.padding(.top,10)
                if selectedAnswer != CrossingAnswer.none {
                    Button() {
                    /// applying final selected answer
                        action?(selectedAnswer)
                    }label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Font.system(size: 40))
                            .foregroundColor(.orange)
                    }
                }
            }.padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }
        .padding()
        
    }
}

