//
//  WidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

enum LengthUnit {
    case feetInch
    case meters
}

struct WidthView: View {
    @Binding var feet: Double
    @Binding var inches: Double
    @State private var isInputValid: Bool = false
    @Binding var isConfirmAlert: Bool
    var unit : LengthUnit = .feetInch

    var body: some View {
        if(unit  == .feetInch ) {
            VStack {
                HStack {
                    TextField("Feet", value: $feet, formatter: NumberFormatter(), onEditingChanged: { _ in
                        validateInput()
                    })
                    .frame(width: 20)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)
                    Text("'").font(.title)
                    
                    TextField("Inches", value: $inches, formatter: NumberFormatter(), onEditingChanged: { _ in
                        validateInput()
                    })
                    .frame(width: 20)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)
                    Text("\"").font(.title)
                    if isInputValid {
                        Button() {
                            isConfirmAlert = true
                        }label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Font.system(size: 40))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            
        }
        else if (unit == .meters) {
            HStack(content: {
                TextField("Inches", value: $inches, formatter: NumberFormatter(), onEditingChanged: { _ in
                    validateInput()
                })
                .frame(width: 20)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)
                
                Text("m").font(.title)
            })
        }
            
    }
    private func validateInput() {
        isInputValid = feet > 0 && inches >= 0
    }
}

#Preview {
    WidthView(feet: .constant(0.0), inches: .constant(0.0), isConfirmAlert: .constant(false))

}
