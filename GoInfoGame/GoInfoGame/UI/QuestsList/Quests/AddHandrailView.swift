//
//  AddHandrailView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 11/01/24.
//

import SwiftUI

struct AddHandrailView: View, AnswerView {
    var selectedQuest: Ques
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundColor(.white)
            .overlay(
                HStack{
                    Spacer()
                    Button {
                    } label: {
                        Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                    }
                    YesNoView()
                }    )
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
            .padding(.top,20)
        }
    }


//#Preview {
//    AddHandrailView()
//}

