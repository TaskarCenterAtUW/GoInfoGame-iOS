//
//  StairFlightsForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 01/04/24.
//

import Foundation
import SwiftUI

struct StairFlightsForm: View, QuestForm {
    var action: ((Int) -> Void)?
    
    typealias AnswerClass = Int
    @State private var numberOfSteps: Int = 0
    @State private var showAlert = false
    @State private var isInputValid: Bool = false
    @State private var isShowingAreYouSure = false
    
    var body: some View {
            VStack{
                QuestionHeader(icon:Image("steps_count"), title: LocalizedStrings.questStairFlights.localized, subtitle: "Stair Flights")
                VStack{
                    HStack {
                        Spacer()
                        TextField("NoOfSteps", value: $numberOfSteps, formatter: NumberFormatter())
                                                .frame(width: 20)
                                                .padding(.horizontal)
                                                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.black), alignment: .bottom)
                                                .textFieldStyle(PlainTextFieldStyle())
                                                .keyboardType(UIKeyboardType.numberPad)
                                                .onChange(of: numberOfSteps) { _ in
                                                    validateInput()
                                                }
                        Image("close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(.leading,20)
                        Image("step")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        if isInputValid {
                            Button() {
                                self.isShowingAreYouSure.toggle()
                            }label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Font.system(size: 40))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }.padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
                
                
            }.padding()
        }
    
    private func validateInput() {
        isInputValid = numberOfSteps > 0
    }
}
