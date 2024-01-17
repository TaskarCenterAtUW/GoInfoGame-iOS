//
//  QuestAnswerView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

protocol AnswerView: View {
    var selectedQuest: Ques { get }
}
struct QuestAndDescriptionView: View {
    @State private var numberOfSteps: Int = 0
    var quest: Ques
    @ViewBuilder
    var answerView:  some View {
            switch quest.answerType {
            case .ADDSIDEWALKWIDTH:
                    SideWalkWidthForm() { feet, inches, isConfirmAlert in
                        print("Feet: \(feet), Inches: \(inches), isConfirmAlert: \(isConfirmAlert)")
                    }
            case .ADDHANDRAIL:
                    AddHandrailView(selectedQuest: quest)
            case .ADDSTEPSRAMP:
                AddStepsRampView()
            case .ADDSTEPSINCLINE:
                AddStepsInclineView()
            case .ADDTACTILEPAVINGSTEPS:
                AddTactilePavingStepsView()
            case .ADDSTAIRNUMBER:
                AddStairNumberView(numberOfSteps: $numberOfSteps){numberOfSteps in 
                    print("numberOfSteps: \(numberOfSteps)")
                }
            case .ADDWAYLIT:
                AddWayLitView()
            case .ADDSTOPELIT:
                AddBusStopLitView()
            }
        }
    var body: some  View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(quest.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .frame(alignment: Alignment.center).padding(.top,20)
                Spacer()
            }
            Text(quest.title)
                .font(.headline)
                .padding(.top,10)
            Text(quest.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top,2)
            answerView
            Spacer()
        }.padding(20)
    }
}
