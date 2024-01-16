//
//  AddStairNumberView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 12/01/24.
//

import SwiftUI

struct AddStairNumberView: View {
    @Binding var numberOfSteps: Int
    @State private var showAlert = false
    @State private var isInputValid: Bool = false
    var onConfirm: ((_ numberOfSteps: Int) -> Void)
    
    var body: some View {
        VStack{
            HStack {
                Spacer()
                
                TextField("NoOfSteps", value: $numberOfSteps, formatter: NumberFormatter(),onEditingChanged: { Bool in
                    validateInput()
                })
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.black), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)
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
                        onConfirm(numberOfSteps)
                    }label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Font.system(size: 40))
                            .foregroundColor(.orange)
                    }
                }
            }
            Divider()
            HStack() {
                Spacer()
                Button {
                    showAlert = true
                } label: {
                    Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("More Questions"))
                }.frame(alignment: .center)
                Spacer()
            }.padding(.top,10)
        }.padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
    }
    private func validateInput() {
        isInputValid = numberOfSteps > 0
    }
}

//#Preview {
//    AddStairNumberView()
//}
