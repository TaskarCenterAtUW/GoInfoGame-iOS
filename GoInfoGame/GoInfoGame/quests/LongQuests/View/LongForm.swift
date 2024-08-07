//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI


struct LongForm: View, QuestForm {
    @ObservedObject private var viewModel = LongFormViewModel()
    
    var action: (([String:String]) -> Void)?
    
    typealias AnswerClass = [String:String]
            
    var body: some View {
        List {
            ForEach(viewModel.longForm!.quests, id: \.questID) { quest in
                if viewModel.shouldShowQuest(quest) {
                    LongQuestView(quest: quest, onChoiceSelected: { selectedAnswerChoice in
                        viewModel.updateAnswers(quest: quest, selectedAnswerChoice: selectedAnswerChoice)
                    })
                }
            }
            
            VStack {
                Button(action: {
                    print("Submit pressed")
                    print(viewModel.answersToBeSubmitted)
                }) {
                    Text("Submit")
                        .font(.custom("Lato-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200, height: 40)
                        .background(Color(red: 135/255, green: 62/255, blue: 242/255))
                        .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    LongForm()
}
