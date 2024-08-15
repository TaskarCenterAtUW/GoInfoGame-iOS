//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI


struct LongForm: View, QuestForm {
    @ObservedObject private var viewModel = LongFormViewModel()
    
    var elementType: LongFormElementType?
    
    var action: (([String:String]) -> Void)?
    
    typealias AnswerClass = [String:String]
    
    @Environment(\.presentationMode) var presentationMode
            
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(elementHeading())")
                    .padding([.leading], 15)
                LongFormDismissButtonView {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding([.all], 20)
            List {
                if let quests = questsForLongForm() {
                    ForEach(quests, id: \.questID) { quest in
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
                            if let action = action {
                                  action(viewModel.answersToBeSubmitted)
                              } else {
                                  print("osmAction is nil")
                              }
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
                } else {
                    Text("No Quests availabke")
                }
            }
        }
    }
    
    func elementHeading() -> String {
        switch elementType {
        case .sidewalk:
            return "Sidewalks"
        case .kerb:
            return "Kerb"
        case .crossing:
            return "Crossings"
        case nil:
            return ""
        }
    }
    
    func questsForLongForm() -> [LongQuest]? {
        var longQuest: [LongQuest]?
        
        switch elementType {
        case .sidewalk:
            longQuest = QuestsRepository.shared.sideWalkLongQuestModel?.quests
        case .kerb:
            longQuest = QuestsRepository.shared.kerbLongQuestModel?.quests
        case .crossing:
            longQuest = QuestsRepository.shared.crossingsLongQuestModel?.quests
        case .none:
            print("None")
        }
        return longQuest
    }
}

#Preview {
    LongForm()
}


enum LongFormElementType {
    case sidewalk,kerb,crossing
}
