//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI


struct LongForm: View, QuestForm {
    
    @State private var selectedAnswers: [UUID: UUID] = [:]
    
    @ObservedObject private var viewModel = LongFormViewModel()
    
    var elementType: LongFormElementType?
    
    var questID: String?
    
    var action: (([String:String]) -> Void)?
    
    typealias AnswerClass = [String:String]
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var shouldShowAlert = false
    
    @State private var alertMessage = ""
            
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text("\(elementHeading())")
                        .font(.custom("Lato-Bold", size: 16))
                      
                    LongFormDismissButtonView {
                        withAnimation {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .padding([.all], 20)
            }
            Text("ID: \(questID ?? "0")")
                .font(.custom("Lato-Regular", size: 13))
                .padding([.leading], 20)
             
            VStack {
                List {
                    if let quests = questsForLongForm() {
                        ForEach(quests, id: \.questID) { quest in
                            if viewModel.shouldShowQuest(quest) {
                                LongQuestView(selectedAnswers: $selectedAnswers, quest: quest, onChoiceSelected: { selectedAnswerChoice in
                                    viewModel.updateAnswers(quest: quest, selectedAnswerChoice: selectedAnswerChoice)
                                },currentAnswer: $viewModel
                                    .answersToBeSubmitted[quest.questTag])
                            }
                        }
                        VStack {
                            Button(action: {
                                if !viewModel.answersToBeSubmitted.isEmpty {
                                    if let action = action {
                                          action(viewModel.answersToBeSubmitted)
                                      }
                                } else {
                                    self.shouldShowAlert = true
                                    self.alertMessage = "Please answer atleast one quest to submit"
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
                        Text("No Quests available")
                    }
                }
            }
        }
        .alert(self.alertMessage, isPresented: $shouldShowAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func elementHeading() -> String {
        switch elementType {
        case .sidewalk:
            return "Sidewalks"
        case .kerb:
            return "Curb"
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
